### CDK-ERIGON VIA KURTOSIS


## What is it ? 

Provision zkEVM L2 networks (now powered by erigon) in <15min with a 1-line cmd !
Under the hood, we use an open-source docker and k8s abstraction called [Kurtosis](https://docs.kurtosis.com/install/)

## How to Run ? (exact steps)

install kurtosis (mac):
```bash
brew install kurtosis-tech/tap/kurtosis-cli
```

** user must have docker-daemon running for next cmds to succeed **

deploy cdk-erigon devnet:
```bash
kurtosis run --enclave erigon --args-file params.yml --image-download always .
```

destroy cdk-erigon devnet:
```bash
kurtosis clean --all
```

## Troubleshooting

initial run logs for reference (*errors on el-lighthouse service*):
```bash
➜  kurtosis-cdk-erigon git:(dan/gke_deploys) ✗ kurtosis run --enclave erigon --args-file params.yml --image-download always .
INFO[2024-05-30T13:37:55-05:00] No Kurtosis engine was found; attempting to start one...
INFO[2024-05-30T13:37:55-05:00] Starting the centralized logs components...
INFO[2024-05-30T13:37:55-05:00] Pulling image 'timberio/vector:0.31.0-debian'
INFO[2024-05-30T13:39:13-05:00] Centralized logs components started.
INFO[2024-05-30T13:39:13-05:00] Pulling image 'traefik:2.10.6'
INFO[2024-05-30T13:40:27-05:00] Reverse proxy started.
INFO[2024-05-30T13:40:27-05:00] Pulling image 'alpine:3.17'
INFO[2024-05-30T13:40:33-05:00] Pulling image 'kurtosistech/engine:0.89.13'
INFO[2024-05-30T13:41:07-05:00] Successfully started Kurtosis engine
INFO[2024-05-30T13:41:07-05:00] Creating a new enclave for Starlark to run inside...
INFO[2024-05-30T13:49:49-05:00] Enclave 'erigon' created successfully
INFO[2024-05-30T13:49:49-05:00] Executing Starlark package at '/Users/dmoore/kurtosis-cdk-erigon' as the passed argument '.' looks like a directory
INFO[2024-05-30T13:49:49-05:00] Compressing package 'github.com/0xPolygon/kurtosis-cdk' at '.' for upload
INFO[2024-05-30T13:49:49-05:00] Uploading and executing package 'github.com/0xPolygon/kurtosis-cdk'

Container images used in this run:
> protolambda/eth2-val-tools:latest - remotely downloaded
> alpine:latest - remotely downloaded
> ethpandaops/ethereum-genesis-generator:3.1.0 - remotely downloaded
> postgres:16.2 - remotely downloaded
> blockscout/blockscout-zkevm:6.5.0 - remotely downloaded
> hermeznetwork/cdk-erigon:20240529132709-3e3013f-amd64 - remotely downloaded
> ghcr.io/blockscout/stats:main - remotely downloaded
> python:3.11-alpine - remotely downloaded
> sigp/lighthouse:v5.1.3 - remotely downloaded
> ghcr.io/blockscout/frontend:v1.30.0 - remotely downloaded
> ghcr.io/blockscout/visualizer:main - remotely downloaded
> badouralix/curl-jq - remotely downloaded
> ethereum/client-go:v1.14.0 - remotely downloaded
> leovct/zkevm-contracts:fork9 - remotely downloaded

WARNING: Container images with different architecture than expected(arm64):
> hermeznetwork/cdk-erigon:20240529132709-3e3013f-amd64 - amd64
> ghcr.io/blockscout/stats:main - amd64
> ghcr.io/blockscout/visualizer:main - amd64

Adding foo service
Service 'foo' added with service UUID 'aec5a5d207fb432889133511fdeed76d'

Uploading file '/static_files/jwt/jwtsecret' to files artifact 'jwt_file'
Files with artifact name 'jwt_file' uploaded with artifact UUID 'acb8eeed4e0e4244879c29819d101841'

Uploading file '/static_files/keymanager/keymanager.txt' to files artifact 'keymanager_file'
Files with artifact name 'keymanager_file' uploaded with artifact UUID 'ebb95ab3fe1a4b42ae31ea03d628ba04'

Printing a message
Read the prometheus, grafana templates

Printing a message
Launching participant network with 1 participants and the following network params struct(deneb_fork_epoch = 0, deposit_contract_address = "0x4242424242424242424242424242424242424242", eip7594_fork_epoch = 1000, eip7594_fork_version = "0x70000038", ejection_balance = 16000000000, electra_fork_epoch = 500, eth1_follow_distance = 2048, genesis_delay = 20, max_churn = 8, min_validator_withdrawability_delay = 256, network = "kurtosis", network_id = "271828", network_sync_base_url = "https://ethpandaops-ethereum-node-snapshots.ams3.digitaloceanspaces.com/", num_validator_keys_per_node = 64, preregistered_validator_count = 0, preregistered_validator_keys_mnemonic = "code code code code code code code code code code code quality", preset = "mainnet", seconds_per_slot = 12, shard_committee_period = 256)

Printing a message
Generating cl validator key stores

Adding service with name 'validator-key-generation-cl-validator-keystore' and image 'protolambda/eth2-val-tools:latest'
Service 'validator-key-generation-cl-validator-keystore' added with service UUID '7cd77a65150649a684d5d3cb4184de1c'

Generating keystores
Command returned with exit code '0' with no output

Verifying whether two values meet a certain condition '=='
Verification succeeded. Value is '0'.

Storing files from service 'validator-key-generation-cl-validator-keystore' at path '/node-0-keystores/' to files artifact with name '1-lighthouse-geth-0-63'
Files with artifact name '1-lighthouse-geth-0-63' uploaded with artifact UUID 'e372db62b9e748ac9b1408770f1acea7'

Storing prysm password in a file
Command returned with exit code '0' with no output

Verifying whether two values meet a certain condition '=='
Verification succeeded. Value is '0'.

Storing files from service 'validator-key-generation-cl-validator-keystore' at path '/tmp/prysm-password.txt' to files artifact with name 'prysm-password'
Files with artifact name 'prysm-password' uploaded with artifact UUID 'bbcc48d98fa94349a2c5b47d520e393b'

Printing a message
{
	"per_node_keystores": [
		{
			"files_artifact_uuid": "1-lighthouse-geth-0-63",
			"nimbus_keys_relative_dirpath": "/nimbus-keys",
			"prysm_relative_dirpath": "/prysm",
			"raw_keys_relative_dirpath": "/keys",
			"raw_root_dirpath": "",
			"raw_secrets_relative_dirpath": "/secrets",
			"teku_keys_relative_dirpath": "/teku-keys",
			"teku_secrets_relative_dirpath": "/teku-secrets"
		}
	],
	"prysm_password_artifact_uuid": "prysm-password",
	"prysm_password_relative_filepath": "prysm-password.txt"
}

Getting final genesis timestamp
Command returned with exit code '0' and the following output: 1717097001

Printing a message
Generating EL CL data

Rendering a template to a files artifact with name 'genesis-el-cl-env-file'
Templates artifact name 'genesis-el-cl-env-file' rendered with artifact UUID 'f0f79154db6448b59a4dad658adbd6e8'

Creating genesis
Command returned with exit code '0' and the following output:
--------------------
+ '[' -f /data/custom_config_data/genesis.json ']'
++ mktemp -d -t ci-XXXXXXXXXX
+ tmp_dir=/tmp/ci-BUGpL0JlK8
+ mkdir -p /data/custom_config_data
+ envsubst
+ python3 /apps/el-gen/genesis_geth.py /tmp/ci-BUGpL0JlK8/genesis-config.yaml
/apps/el-gen/.venv/lib/python3.11/site-packages/eth_utils/network.py:61: UserWarning: Network 345 with name 'Yooldo Verse Mainnet' does not have a valid ChainId. eth-typing should be updated with the latest networks.
  networks = initialize_network_objects()
/apps/el-gen/.venv/lib/python3.11/site-packages/eth_utils/network.py:61: UserWarning: Network 12611 with name 'Astar zkEVM' does not have a valid ChainId. eth-typing should be updated with the latest networks.
  networks = initialize_network_objects()
+ python3 /apps/el-gen/genesis_chainspec.py /tmp/ci-BUGpL0JlK8/genesis-config.yaml
/apps/el-gen/.venv/lib/python3.11/site-packages/eth_utils/network.py:61: UserWarning: Network 345 with name 'Yooldo Verse Mainnet' does not have a valid ChainId. eth-typing should be updated with the latest networks.
  networks = initialize_network_objects()
/apps/el-gen/.venv/lib/python3.11/site-packages/eth_utils/network.py:61: UserWarning: Network 12611 with name 'Astar zkEVM' does not have a valid ChainId. eth-typing should be updated with the latest networks.
  networks = initialize_network_objects()
+ python3 /apps/el-gen/genesis_besu.py /tmp/ci-BUGpL0JlK8/genesis-config.yaml
/apps/el-gen/.venv/lib/python3.11/site-packages/eth_utils/network.py:61: UserWarning: Network 345 with name 'Yooldo Verse Mainnet' does not have a valid ChainId. eth-typing should be updated with the latest networks.
  networks = initialize_network_objects()
/apps/el-gen/.venv/lib/python3.11/site-packages/eth_utils/network.py:61: UserWarning: Network 12611 with name 'Astar zkEVM' does not have a valid ChainId. eth-typing should be updated with the latest networks.
  networks = initialize_network_objects()
+ gen_cl_config
+ . /apps/el-gen/.venv/bin/activate
++ '[' /apps/el-gen/.venv/bin/activate = ./entrypoint.sh ']'
++ deactivate nondestructive
++ unset -f pydoc
++ '[' -z _ ']'
++ PATH=/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
++ export PATH
++ unset _OLD_VIRTUAL_PATH
++ '[' -z '' ']'
++ hash -r
++ '[' -z _ ']'
++ PS1=
++ export PS1
++ unset _OLD_VIRTUAL_PS1
++ unset VIRTUAL_ENV
++ unset VIRTUAL_ENV_PROMPT
++ '[' '!' nondestructive = nondestructive ']'
++ VIRTUAL_ENV=/apps/el-gen/.venv
++ '[' linux-gnu = cygwin ']'
++ '[' linux-gnu = msys ']'
++ export VIRTUAL_ENV
++ _OLD_VIRTUAL_PATH=/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
++ PATH=/apps/el-gen/.venv/bin:/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
++ export PATH
++ '[' xel-gen '!=' x ']'
++ VIRTUAL_ENV_PROMPT=el-gen
++ export VIRTUAL_ENV_PROMPT
++ '[' -z '' ']'
++ '[' -z '' ']'
++ _OLD_VIRTUAL_PS1=
++ PS1='(el-gen) '
++ export PS1
++ alias pydoc
++ true
++ hash -r
+ set -x
+ '[' -f /data/custom_config_data/genesis.ssz ']'
++ mktemp -d -t ci-XXXXXXXXXX
+ tmp_dir=/tmp/ci-SV9TycWntl
+ mkdir -p /data/custom_config_data
+ envsubst
+ envsubst
+ [[ mainnet == \m\i\n\i\m\a\l ]]
+ cp /tmp/ci-SV9TycWntl/mnemonics.yaml /data/custom_config_data/mnemonics.yaml
+ grep DEPOSIT_CONTRACT_ADDRESS /data/custom_config_data/config.yaml
+ cut -d ' ' -f2
+ echo 0
+ echo 0
+ echo
+ echo '- '
+ envsubst
+ genesis_args=(deneb --config /data/custom_config_data/config.yaml --mnemonics $tmp_dir/mnemonics.yaml --tranches-dir /data/custom_config_data/tranches --state-output /data/custom_config_data/genesis.ssz --preset-phase0 $PRESET_BASE --preset-altair $PRESET_BASE --preset-bellatrix $PRESET_BASE --preset-capella $PRESET_BASE --preset-deneb $PRESET_BASE)
+ [[ 0x00 == \0\x\0\1 ]]
+ [[ '' != '' ]]
+ [[ '' != '' ]]
+ genesis_args+=(--eth1-config /data/custom_config_data/genesis.json)
+ '[' -z '' ']'
+ zcli_args=(pretty deneb BeaconState --preset-phase0 $PRESET_BASE --preset-altair $PRESET_BASE --preset-bellatrix $PRESET_BASE --preset-capella $PRESET_BASE --preset-deneb $PRESET_BASE /data/custom_config_data/genesis.ssz)
+ /usr/local/bin/eth2-testnet-genesis deneb --config /data/custom_config_data/config.yaml --mnemonics /tmp/ci-SV9TycWntl/mnemonics.yaml --tranches-dir /data/custom_config_data/tranches --state-output /data/custom_config_data/genesis.ssz --preset-phase0 mainnet --preset-altair mainnet --preset-bellatrix mainnet --preset-capella mainnet --preset-deneb mainnet --eth1-config /data/custom_config_data/genesis.json
zrnt version: v0.32.3
Using CL MIN_GENESIS_TIME for genesis timestamp
processing mnemonic 0, for 64 validators
Writing pubkeys list file...
generated 64 validators from mnemonic yaml (/tmp/ci-SV9TycWntl/mnemonics.yaml)
eth2 genesis at 1717097001 + 20 = 1717097021  (2024-05-30 19:23:41 +0000 UTC)
done preparing state, serializing SSZ now...
done!
+ /usr/local/bin/zcli pretty deneb BeaconState --preset-phase0 mainnet --preset-altair mainnet --preset-bellatrix mainnet --preset-capella mainnet --preset-deneb mainnet /data/custom_config_data/genesis.ssz
Genesis args: deneb --config /data/custom_config_data/config.yaml --mnemonics /tmp/ci-SV9TycWntl/mnemonics.yaml --tranches-dir /data/custom_config_data/tranches --state-output /data/custom_config_data/genesis.ssz --preset-phase0 mainnet --preset-altair mainnet --preset-bellatrix mainnet --preset-capella mainnet --preset-deneb mainnet --eth1-config /data/custom_config_data/genesis.json
+ echo 'Genesis args: deneb' --config /data/custom_config_data/config.yaml --mnemonics /tmp/ci-SV9TycWntl/mnemonics.yaml --tranches-dir /data/custom_config_data/tranches --state-output /data/custom_config_data/genesis.ssz --preset-phase0 mainnet --preset-altair mainnet --preset-bellatrix mainnet --preset-capella mainnet --preset-deneb mainnet --eth1-config /data/custom_config_data/genesis.json
++ jq -r .latest_execution_payload_header.block_number /data/custom_config_data/parsedBeaconState.json
+ echo 'Genesis block number: 0'
Genesis block number: 0
++ jq -r .latest_execution_payload_header.block_hash /data/custom_config_data/parsedBeaconState.json
Genesis block hash: 0xecabb1af033fa5fb4046a76be9394d3f8e91b9b8f1078ae2aa59e38062107dbc
+ echo 'Genesis block hash: 0xecabb1af033fa5fb4046a76be9394d3f8e91b9b8f1078ae2aa59e38062107dbc'
+ jq -r .eth1_data.block_hash /data/custom_config_data/parsedBeaconState.json
+ tr -d '\n'
+ jq -r .genesis_validators_root /data/custom_config_data/parsedBeaconState.json
+ tr -d '\n'
+ gen_shared_files
+ . /apps/el-gen/.venv/bin/activate
++ '[' /apps/el-gen/.venv/bin/activate = ./entrypoint.sh ']'
++ deactivate nondestructive
++ unset -f pydoc
++ '[' -z _ ']'
++ PATH=/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
++ export PATH
++ unset _OLD_VIRTUAL_PATH
++ '[' -z '' ']'
++ hash -r
++ '[' -z _ ']'
++ PS1=
++ export PS1
++ unset _OLD_VIRTUAL_PS1
++ unset VIRTUAL_ENV
++ unset VIRTUAL_ENV_PROMPT
++ '[' '!' nondestructive = nondestructive ']'
++ VIRTUAL_ENV=/apps/el-gen/.venv
++ '[' linux-gnu = cygwin ']'
++ '[' linux-gnu = msys ']'
++ export VIRTUAL_ENV
++ _OLD_VIRTUAL_PATH=/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
++ PATH=/apps/el-gen/.venv/bin:/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
++ export PATH
++ '[' xel-gen '!=' x ']'
++ VIRTUAL_ENV_PROMPT=el-gen
++ export VIRTUAL_ENV_PROMPT
++ '[' -z '' ']'
++ '[' -z '' ']'
++ _OLD_VIRTUAL_PS1=
++ PS1='(el-gen) '
++ export PS1
++ alias pydoc
++ true
++ hash -r
+ set -x
+ mkdir -p /data/custom_config_data
+ '[' -f /data/jwt/jwtsecret ']'
+ mkdir -p /data/jwt
++ openssl rand -hex 32
++ tr -d '\n'
+ echo -n 0x4e0a404b7561ca35e95db52054d95c12b93a06e23ec0b2446eaba582d7db4f53
+ '[' -f /data/custom_config_data/genesis.json ']'
++ cat /data/custom_config_data/genesis.json
++ jq -r '.config.terminalTotalDifficulty | tostring'
+ terminalTotalDifficulty=0
+ sed -i 's/TERMINAL_TOTAL_DIFFICULTY:.*/TERMINAL_TOTAL_DIFFICULTY: 0/' /data/custom_config_data/config.yaml
+ '[' false = true ']'

--------------------

Reading genesis validators root
Command returned with exit code '0' and the following output: 0xcf025a530376ae32ce7555f1618f6b50003d7f67cabc879780f0366716c03299

Reading cancun time from genesis
Command returned with exit code '0' and the following output: 0

Reading prague time from genesis
Command returned with exit code '0' and the following output: 1717289021

Adding service with name 'el-1-geth-lighthouse' and image 'ethereum/client-go:v1.14.0'
There was an error executing Starlark code
An error occurred executing instruction (number 22) at github.com/kurtosis-tech/ethereum-package/src/el/geth/geth_launcher.star[155:31]:
  add_service(name="el-1-geth-lighthouse", config=ServiceConfig(image="ethereum/client-go:v1.14.0", ports={"engine-rpc": PortSpec(number=8551, transport_protocol="TCP", application_protocol=""), "metrics": PortSpec(number=9001, transport_protocol="TCP", application_protocol=""), "rpc": PortSpec(number=8545, transport_protocol="TCP", application_protocol="http"), "tcp-discovery": PortSpec(number=30303, transport_protocol="TCP", application_protocol=""), "udp-discovery": PortSpec(number=30303, transport_protocol="UDP", application_protocol=""), "ws": PortSpec(number=8546, transport_protocol="TCP", application_protocol="")}, public_ports={}, files={"/jwt": "jwt_file", "/network-configs": "el_cl_genesis_data"}, entrypoint=["sh", "-c"], cmd=["geth init --state.scheme=path --datadir=/data/geth/execution-data /network-configs/genesis.json && geth --state.scheme=path     --networkid=271828 --verbosity=3 --datadir=/data/geth/execution-data --http --http.addr=0.0.0.0 --http.vhosts=* --http.corsdomain=* --http.api=admin,engine,net,eth,web3,debug --ws --ws.addr=0.0.0.0 --ws.port=8546 --ws.api=admin,engine,net,eth,web3,debug --ws.origins=* --allow-insecure-unlock --nat=extip:KURTOSIS_IP_ADDR_PLACEHOLDER --verbosity=3 --authrpc.port=8551 --authrpc.addr=0.0.0.0 --authrpc.vhosts=* --authrpc.jwtsecret=/jwt/jwtsecret --syncmode=full --rpc.allow-unprotected-txs --metrics --metrics.addr=0.0.0.0 --metrics.port=9001 --discovery.port=30303 --port=30303"], env_vars={}, private_ip_address_placeholder="KURTOSIS_IP_ADDR_PLACEHOLDER", max_cpu=1000, min_cpu=300, max_memory=1024, min_memory=512, labels={"ethereum-package.client": "geth", "ethereum-package.client-image": "ethereum-client-go-v1.14.0", "ethereum-package.client-type": "execution", "ethereum-package.connected-client": "lighthouse"}, tolerations=[], node_selectors={}))
  Caused by: Unexpected error occurred starting service 'el-1-geth-lighthouse'
  Caused by: An error occurred waiting for all TCP and UDP ports to be open for service 'el-1-geth-lighthouse' with private IP '172.16.0.12'; this is usually due to a misconfiguration in the service itself, so here are the logs:
  == SERVICE 'el-1-geth-lighthouse' LOGS ===================================
  INFO [05-30|19:23:10.384] Maximum peer count                       ETH=50 total=50
  INFO [05-30|19:23:10.387] Smartcard socket not found, disabling    err="stat /run/pcscd/pcscd.comm: no such file or directory"
  INFO [05-30|19:23:10.390] Set global gas cap                       cap=50,000,000
  INFO [05-30|19:23:10.390] Initializing the KZG library             backend=gokzg
  INFO [05-30|19:23:10.575] Defaulting to pebble as the backing database
  INFO [05-30|19:23:10.577] Allocated cache and file handles         database=/data/geth/execution-data/geth/chaindata cache=16.00MiB handles=16
  INFO [05-30|19:23:10.676] Opened ancient database                  database=/data/geth/execution-data/geth/chaindata/ancient/chain readonly=false
  INFO [05-30|19:23:10.677] State scheme set by user                 scheme=path
  ERROR[05-30|19:23:10.677] Zero trie root hash!
  ERROR[05-30|19:23:10.679] Head block is not reachable
  INFO [05-30|19:23:10.731] Opened ancient database                  database=/data/geth/execution-data/geth/chaindata/ancient/state readonly=false
  INFO [05-30|19:23:10.731] Writing custom genesis block
  INFO [05-30|19:23:10.886] Successfully wrote genesis state         database=chaindata hash=ecabb1..107dbc
  INFO [05-30|19:23:10.886] Defaulting to pebble as the backing database
  INFO [05-30|19:23:10.886] Allocated cache and file handles         database=/data/geth/execution-data/geth/lightchaindata cache=16.00MiB handles=16
  INFO [05-30|19:23:10.998] Opened ancient database                  database=/data/geth/execution-data/geth/lightchaindata/ancient/chain readonly=false
  ERROR[05-30|19:23:10.999] Head block is not reachable
  INFO [05-30|19:23:10.999] State scheme set by user                 scheme=path
  ERROR[05-30|19:23:10.999] Zero trie root hash!
  INFO [05-30|19:23:11.082] Opened ancient database                  database=/data/geth/execution-data/geth/lightchaindata/ancient/state readonly=false
  INFO [05-30|19:23:11.082] Writing custom genesis block
  INFO [05-30|19:23:11.196] Successfully wrote genesis state         database=lightchaindata hash=ecabb1..107dbc
  INFO [05-30|19:23:11.420] Enabling metrics collection
  INFO [05-30|19:23:11.420] Enabling stand-alone metrics HTTP endpoint address=0.0.0.0:9001
  INFO [05-30|19:23:11.420] Starting metrics server                  addr=http://0.0.0.0:9001/debug/metrics
  INFO [05-30|19:23:11.422] Maximum peer count                       ETH=50 total=50
  INFO [05-30|19:23:11.424] Smartcard socket not found, disabling    err="stat /run/pcscd/pcscd.comm: no such file or directory"
  INFO [05-30|19:23:11.431] Set global gas cap                       cap=50,000,000
  INFO [05-30|19:23:11.431] Initializing the KZG library             backend=gokzg
  INFO [05-30|19:23:11.706] Allocated trie memory caches             clean=154.00MiB dirty=256.00MiB
  INFO [05-30|19:23:11.707] Using pebble as the backing database
  INFO [05-30|19:23:11.707] Allocated cache and file handles         database=/data/geth/execution-data/geth/chaindata cache=512.00MiB handles=524,288
  INFO [05-30|19:23:11.796] Opened ancient database                  database=/data/geth/execution-data/geth/chaindata/ancient/chain readonly=false
  INFO [05-30|19:23:11.796] State scheme set by user                 scheme=path
  INFO [05-30|19:23:11.797] Initialising Ethereum protocol           network=271,828 dbversion=<nil>
  INFO [05-30|19:23:11.805] Failed to load journal, discard it       err="journal not found"
  INFO [05-30|19:23:11.830] Opened ancient database                  database=/data/geth/execution-data/geth/chaindata/ancient/state readonly=false
  INFO [05-30|19:23:11.830]
  INFO [05-30|19:23:11.830] ---------------------------------------------------------------------------------------------------------------------------------------------------------
  INFO [05-30|19:23:11.830] Chain ID:  271828 (unknown)
  INFO [05-30|19:23:11.830] Consensus: unknown
  INFO [05-30|19:23:11.830]
  INFO [05-30|19:23:11.830] Pre-Merge hard forks (block based):
  INFO [05-30|19:23:11.830]  - Homestead:                   #0        (https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/homestead.md)
  INFO [05-30|19:23:11.830]  - Tangerine Whistle (EIP 150): #0        (https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/tangerine-whistle.md)
  INFO [05-30|19:23:11.830]  - Spurious Dragon/1 (EIP 155): #0        (https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/spurious-dragon.md)
  INFO [05-30|19:23:11.830]  - Spurious Dragon/2 (EIP 158): #0        (https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/spurious-dragon.md)
  INFO [05-30|19:23:11.830]  - Byzantium:                   #0        (https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/byzantium.md)
  INFO [05-30|19:23:11.830]  - Constantinople:              #0        (https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/constantinople.md)
  INFO [05-30|19:23:11.830]  - Petersburg:                  #0        (https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/petersburg.md)
  INFO [05-30|19:23:11.830]  - Istanbul:                    #0        (https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/istanbul.md)
  INFO [05-30|19:23:11.830]  - Berlin:                      #0        (https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/berlin.md)
  INFO [05-30|19:23:11.830]  - London:                      #0        (https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/london.md)
  INFO [05-30|19:23:11.830]
  INFO [05-30|19:23:11.830] Merge configured:
  INFO [05-30|19:23:11.830]  - Hard-fork specification:    https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/paris.md
  INFO [05-30|19:23:11.830]  - Network known to be merged: true
  INFO [05-30|19:23:11.830]  - Total terminal difficulty:  0
  INFO [05-30|19:23:11.830]  - Merge netsplit block:       #0
  INFO [05-30|19:23:11.830]
  INFO [05-30|19:23:11.830] Post-Merge hard forks (timestamp based):
  INFO [05-30|19:23:11.830]  - Shanghai:                    @0          (https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/shanghai.md)
  INFO [05-30|19:23:11.830]  - Cancun:                      @0          (https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/cancun.md)
  INFO [05-30|19:23:11.830]  - Prague:                      @1717289021
  INFO [05-30|19:23:11.830]
  INFO [05-30|19:23:11.830] ---------------------------------------------------------------------------------------------------------------------------------------------------------
  INFO [05-30|19:23:11.830]
  INFO [05-30|19:23:11.831] Loaded most recent local block           number=0 hash=ecabb1..107dbc td=1 age=0
  WARN [05-30|19:23:11.832] Failed to load snapshot                  err="missing or corrupted snapshot"
  INFO [05-30|19:23:11.844] Rebuilding state snapshot
  INFO [05-30|19:23:11.847] Initialized transaction indexer          range="last 2350000 blocks"
  INFO [05-30|19:23:11.848] Resuming state snapshot generation       root=a54bac..771e18 accounts=0 slots=0 storage=0.00B dangling=0 elapsed=4.637ms
  INFO [05-30|19:23:11.866] Generated state snapshot                 accounts=279 slots=31 storage=13.66KiB dangling=0 elapsed=22.067ms
  INFO [05-30|19:23:12.188] Unprotected transactions allowed
  INFO [05-30|19:23:12.189] Gasprice oracle is ignoring threshold set threshold=2
  WARN [05-30|19:23:12.223] Engine API enabled                       protocol=eth
  INFO [05-30|19:23:12.225] Starting peer-to-peer node               instance=Geth/v1.14.0-stable-87246f3c/linux-arm64/go1.22.2
  INFO [05-30|19:23:12.287] New local node record                    seq=1,717,096,992,280 id=dca76cd2ef7266f2 ip=172.16.0.12 udp=30303 tcp=30303
  INFO [05-30|19:23:12.309] IPC endpoint opened                      url=/data/geth/execution-data/geth.ipc
  INFO [05-30|19:23:12.311] Started P2P networking                   self=enode://b65ce4bb857774eff1e04d9b24a8b22c292396f3b14d89c419fc9dc9279a420492578ea31ddc7a41a578aefb76c52f254772128c6bd8235ac8d074f37a37bc63@172.16.0.12:30303
  INFO [05-30|19:23:12.312] Loaded JWT secret file                   path=/jwt/jwtsecret crc32=0xec7a0f2c
  INFO [05-30|19:23:12.312] HTTP server started                      endpoint=[::]:8545 auth=false prefix= cors=* vhosts=*
  INFO [05-30|19:23:12.313] WebSocket enabled                        url=ws://[::]:8546
  INFO [05-30|19:23:12.313] WebSocket enabled                        url=ws://[::]:8551
  INFO [05-30|19:23:12.313] HTTP server started                      endpoint=[::]:8551 auth=true  prefix= cors=localhost vhosts=*
  ERROR[05-30|19:23:12.315] Low disk space. Gracefully shutting down Geth to prevent database corruption. available=0.00B path=/data/geth/execution-data/geth
  INFO [05-30|19:23:12.315] Got interrupt, shutting down...
  INFO [05-30|19:23:12.315] HTTP server stopped                      endpoint=[::]:8545
  INFO [05-30|19:23:12.315] HTTP server stopped                      endpoint=[::]:8546
  INFO [05-30|19:23:12.315] HTTP server stopped                      endpoint=[::]:8551
  INFO [05-30|19:23:12.315] IPC endpoint closed                      url=/data/geth/execution-data/geth.ipc
  INFO [05-30|19:23:12.315] Ethereum protocol stopped
  INFO [05-30|19:23:12.315] Transaction pool stopped
  INFO [05-30|19:23:12.345] Persisting dirty state to disk           root=a54bac..771e18 layers=0
  INFO [05-30|19:23:12.351] Persisted dirty state to disk            size=69.00B elapsed=5.803ms
  INFO [05-30|19:23:12.374] Blockchain stopped

  == FINISHED SERVICE 'el-1-geth-lighthouse' LOGS ===================================
  Caused by: An error occurred while waiting for all TCP and UDP ports to be open
  Caused by: Unsuccessful ports check for IP '172.16.0.12' and port spec '{privatePortSpec:0x400099a4e0}', even after '240' retries with '500' milliseconds in between retries. Timeout '2m0s' has been reached
  Caused by: An error occurred while calling network address '172.16.0.12:8551' with port protocol 'TCP' and using time out '200ms'
  Caused by: dial tcp 172.16.0.12:8551: connect: no route to host

Error encountered running Starlark code.

⭐ us on GitHub - https://github.com/kurtosis-tech/kurtosis
INFO[2024-05-30T14:25:10-05:00] ===============================================
INFO[2024-05-30T14:25:10-05:00] ||          Created enclave: erigon          ||
INFO[2024-05-30T14:25:10-05:00] ===============================================
Name:            erigon
UUID:            e901c45bc21a
Status:          RUNNING
Creation Time:   Thu, 30 May 2024 13:41:07 CDT
Flags:

========================================= Files Artifacts =========================================
UUID           Name
e372db62b9e7   1-lighthouse-geth-0-63
94ca7cddef00   el_cl_genesis_data
c7081babd811   final-genesis-timestamp
f0f79154db64   genesis-el-cl-env-file
35d2c46fbc3b   genesis_validators_root
acb8eeed4e0e   jwt_file
ebb95ab3fe1a   keymanager_file
bbcc48d98fa9   prysm-password

========================================== User Services ==========================================
UUID           Name                                             Ports    Status
aec5a5d207fb   foo                                              <none>   RUNNING
7cd77a651506   validator-key-generation-cl-validator-keystore   <none>   RUNNING
```
