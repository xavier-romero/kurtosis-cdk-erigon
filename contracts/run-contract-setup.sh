#!/bin/bash
# This script is responsible for deploying the contracts for zkEVM/CDK.

echo_ts() {
    timestamp=$(date +"[%Y-%m-%d %H:%M:%S]")
    echo "$timestamp $1"
}

wait_for_rpc_to_be_available() {
    rpc_url="$1"
    counter=0
    max_retries=20
    until cast send --rpc-url "{{.l1_rpc_url}}" --mnemonic "{{.l1_preallocated_mnemonic}}" --value 0 "{{.sequencer.address}}"; do
        ((counter++))
        echo_ts "L1 RPC might not be ready... Retrying ($counter)..."
        if [ $counter -ge $max_retries ]; then
            echo_ts "Exceeded maximum retry attempts. Exiting."
            exit 1
        fi
        sleep 5
    done
}

fund_account_on_l1() {
    name="$1"
    address="$2"
    echo_ts "Funding $name account"
    cast send \
        --rpc-url "{{.l1_rpc_url}}" \
        --mnemonic "{{.l1_preallocated_mnemonic}}" \
        --value "{{.l1_funding_amount}}" \
        "$address"
}

# We want to avoid running this script twice.
# In the future it might make more sense to exit with an error code.
if [[ -e "/opt/zkevm/.init-complete.lock" ]]; then
    echo "This script has already been executed"
    exit
fi

# Wait for the L1 RPC to be available.
echo_ts "Waiting for the L1 RPC to be available"
wait_for_rpc_to_be_available "{{.l1_rpc_url}}"
echo_ts "L1 RPC is now available"

# Fund accounts on L1.
echo_ts "Funding important accounts on l1"
fund_account_on_l1 "admin" "{{.admin.address}}"
fund_account_on_l1 "sequencer" "{{.sequencer.address}}"
fund_account_on_l1 "aggregator" "{{.aggregator.address}}"
fund_account_on_l1 "agglayer" "{{.agglayer.address}}"
fund_account_on_l1 "claimtxmanager" "{{.claimtxmanager.address}}"

# Configure zkevm contract deploy parameters.
pushd /opt/zkevm-contracts || exit 1
cp /opt/contract-deploy/deploy_parameters.json /opt/zkevm-contracts/deployment/v2/deploy_parameters.json
cp /opt/contract-deploy/create_rollup_parameters.json /opt/zkevm-contracts/deployment/v2/create_rollup_parameters.json
sed -i 's#http://127.0.0.1:8545#{{.l1_rpc_url}}#' hardhat.config.ts

# Deploy gas token.
# shellcheck disable=SC1054,SC1083
{{if .zkevm_use_gas_token_contract}}
echo_ts "Deploying gas token to L1"
printf "[profile.default]\nsrc = 'contracts'\nout = 'out'\nlibs = ['node_modules']\n" > foundry.toml
forge create \
    --json \
    --rpc-url "{{.l1_rpc_url}}" \
    --mnemonic "{{.l1_preallocated_mnemonic}}" \
    contracts/mocks/ERC20PermitMock.sol:ERC20PermitMock \
    --constructor-args  "CDK Gas Token" "CDK" "{{.admin.address}}" "1000000000000000000000000" > gasToken-erc20.json

# In this case, we'll configure the create rollup parameters to have a gas token
jq --slurpfile c gasToken-erc20.json '.gasTokenAddress = $c[0].deployedTo' /opt/contract-deploy/create_rollup_parameters.json > /opt/zkevm-contracts/deployment/v2/create_rollup_parameters.json
# shellcheck disable=SC1056,SC1072,SC1073,SC1009
{{end}}

# Deploy contracts.
echo_ts "Deploying zkevm contracts to L1"

echo_ts "Step 1: Preparing tesnet"
npx hardhat run deployment/testnet/prepareTestnet.ts --network localhost | tee 01_prepare_testnet.out

echo_ts "Step 2: Creating genesis"
MNEMONIC="{{.l1_preallocated_mnemonic}}" npx ts-node deployment/v2/1_createGenesis.ts | tee 02_create_genesis.out

echo_ts "Step 3: Deploying PolygonZKEVMDeployer"
npx hardhat run deployment/v2/2_deployPolygonZKEVMDeployer.ts --network localhost | tee 03_zkevm_deployer.out

echo_ts "Step 4: Deploying contracts"
npx hardhat run deployment/v2/3_deployContracts.ts --network localhost | tee 04_deploy_contracts.out

echo_ts "Step 5: Creating rollup"
npx hardhat run deployment/v2/4_createRollup.ts --network localhost | tee 05_create_rollup.out

# Combine contract deploy files.
# At this point, all of the contracts /should/ have been deployed.
# Now we can combine all of the files and put them into the general zkevm folder.
echo_ts "Combining contract deploy files"
mkdir -p /opt/zkevm
cp /opt/zkevm-contracts/deployment/v2/deploy_*.json /opt/zkevm/
cp /opt/zkevm-contracts/deployment/v2/genesis.json /opt/zkevm/
cp /opt/zkevm-contracts/deployment/v2/create_rollup_output.json /opt/zkevm/
cp /opt/zkevm-contracts/deployment/v2/create_rollup_parameters.json /opt/zkevm/
popd

# Combine contract deploy data.
pushd /opt/zkevm/ || exit 1
echo_ts "Creating combined.json"
cp genesis.json genesis.original.json
jq --slurpfile rollup create_rollup_output.json '. + $rollup[0]' deploy_output.json > combined.json

# Add the L2 GER Proxy address in combined.json (for panoptichain).
zkevm_global_exit_root_l2_address=$(jq -r '.genesis[] | select(.contractName == "PolygonZkEVMGlobalExitRootL2 proxy") | .address' /opt/zkevm/genesis.json)
jq --arg a "$zkevm_global_exit_root_l2_address" '.polygonZkEVMGlobalExitRootL2Address = $a' combined.json > c.json; mv c.json combined.json

# There are a bunch of fields that need to be renamed in order for the
# older fork7 code to be compatible with some of the fork8
# automations. This schema matching can be dropped once this is
# versioned up to 8
fork_id="{{.rollup_fork_id}}"
if [[ fork_id -lt 8 ]]; then
    jq '.polygonRollupManagerAddress = .polygonRollupManager' combined.json > c.json; mv c.json combined.json
    jq '.deploymentRollupManagerBlockNumber = .deploymentBlockNumber' combined.json > c.json; mv c.json combined.json
    jq '.upgradeToULxLyBlockNumber = .deploymentBlockNumber' combined.json > c.json; mv c.json combined.json
    # jq '.polygonDataCommitteeAddress = .polygonDataCommittee' combined.json > c.json; mv c.json combined.json
    jq '.createRollupBlockNumber = .createRollupBlock' combined.json > c.json; mv c.json combined.json
fi

# NOTE there is a disconnect in the necessary configurations here between the validium node and the zkevm node
jq --slurpfile c combined.json '.rollupCreationBlockNumber = $c[0].createRollupBlockNumber' genesis.json > g.json; mv g.json genesis.json
jq --slurpfile c combined.json '.rollupManagerCreationBlockNumber = $c[0].upgradeToULxLyBlockNumber' genesis.json > g.json; mv g.json genesis.json
jq --slurpfile c combined.json '.genesisBlockNumber = $c[0].createRollupBlockNumber' genesis.json > g.json; mv g.json genesis.json
jq --slurpfile c combined.json '.l1Config = {chainId:{{.l1_chain_id}}}' genesis.json > g.json; mv g.json genesis.json
jq --slurpfile c combined.json '.l1Config.polygonZkEVMGlobalExitRootAddress = $c[0].polygonZkEVMGlobalExitRootAddress' genesis.json > g.json; mv g.json genesis.json
jq --slurpfile c combined.json '.l1Config.polygonRollupManagerAddress = $c[0].polygonRollupManagerAddress' genesis.json > g.json; mv g.json genesis.json
jq --slurpfile c combined.json '.l1Config.polTokenAddress = $c[0].polTokenAddress' genesis.json > g.json; mv g.json genesis.json
jq --slurpfile c combined.json '.l1Config.polygonZkEVMAddress = $c[0].rollupAddress' genesis.json > g.json; mv g.json genesis.json

# Configure contracts.

# The sequencer needs to pay POL when it sequences batches.
# This gets refunded when the batches are proved.
# In order for this to work t,he rollup address must be approved to transfer the sequencers' POL tokens.
echo_ts "Approving the rollup address to transfer POL tokens on behalf of the sequencer"
cast send \
    --private-key "{{.sequencer.private_key}}" \
    --legacy \
    --rpc-url "{{.l1_rpc_url}}" \
    "$(jq -r '.polTokenAddress' combined.json)" \
    'approve(address,uint256)(bool)' \
    "$(jq -r '.rollupAddress' combined.json)" 1000000000000000000000000000

# The DAC needs to be configured with a required number of signatures.
# Right now the number of DAC nodes is not configurable.
# If we add more nodes, we'll need to make sure the urls and keys are sorted.
echo_ts "Setting the data availability committee"
cast send \
    --private-key "{{.admin.private_key}}" \
    --rpc-url "{{.l1_rpc_url}}" \
    "$(jq -r '.polygonDataCommitteeAddress' combined.json)" \
    'function setupCommittee(uint256 _requiredAmountOfSignatures, string[] urls, bytes addrsBytes) returns()' \
    1 ["{{.dac_url}}"] "{{.dac.address}}"

# The DAC needs to be enabled with a call to set the DA protocol.
echo_ts "Setting the data availability protocol"
cast send \
    --private-key "{{.admin.private_key}}" \
    --rpc-url "{{.l1_rpc_url}}" \
    "$(jq -r '.rollupAddress' combined.json)" \
    'setDataAvailabilityProtocol(address)' \
    "$(jq -r '.polygonDataCommitteeAddress' combined.json)"

# Grant the aggregator role to the agglayer so that it can also verify batches.
# cast keccak "TRUSTED_AGGREGATOR_ROLE"
echo_ts "Granting the aggregator role to the agglayer so that it can also verify batches"
cast send \
    --private-key "{{.admin.private_key}}" \
    --rpc-url "{{.l1_rpc_url}}" \
    "$(jq -r '.polygonRollupManagerAddress' combined.json)" \
    'grantRole(bytes32,address)' \
    "0x084e94f375e9d647f87f5b2ceffba1e062c70f6009fdbcf80291e803b5c9edd4" "{{.agglayer.address}}"

# The contract setup is done!
touch .init-complete.lock
