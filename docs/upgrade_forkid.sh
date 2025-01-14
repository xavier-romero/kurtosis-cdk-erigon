#!/bin/bash
SOURCE_FORKID=11
TARGET_FORKID=12
REPO_FOLDER=/home/xavi/repos/kurtosis-cdk-erigon
STACK_NAME=cdk


cd $REPO_FOLDER
KURTOSIS_CONFIG=upgrade_from_${SOURCE_FORKID}_to_${TARGET_FORKID}.json
cp forkid${SOURCE_FORKID}.json $KURTOSIS_CONFIG

# deploy stack and send test tx
kurtosis run --enclave $STACK_NAME . '{"config": "'$KURTOSIS_CONFIG'"}'
PRIV_KEY=0x42b6e34dc21598a807dc19d7784c71b2a7a01f6480dc6f58258f78e539f1a1fa
cast send --rpc-url $(kurtosis port print $STACK_NAME rpc001 rpc8123) --legacy --private-key $PRIV_KEY --value 0.01ether 0x0000000000000000000000000000000000000000

# Halt sequencer
kurtosis service exec $STACK_NAME sequencer001 "HALTON=\$(printf \"%d\\n\" \$((\$(curl -s -X POST -H \"Content-Type: application/json\" -d '{\"method\":\"zkevm_batchNumber\",\"id\":1,\"jsonrpc\":\"2.0\"}' http://localhost:8123 | jq -r .result)+2))); echo \"zkevm.sequencer-halt-on-batch-number: \$HALTON\" >> /etc/erigon/erigon-sequencer.yaml"
kurtosis service stop $STACK_NAME sequencer001
kurtosis service start $STACK_NAME sequencer001

# Wait for sequencer to be halted
while ! kurtosis service logs -n 1 $STACK_NAME sequencer001 | grep -q "Halt sequencer on batch"; do
    echo "Waiting for sequencer to halt"
    sleep 3
done

# create env file for the commands we need to execute on contracts service
kurtosis service exec $STACK_NAME contracts001 "echo 'cd /output' > /commands.sh"
kurtosis service exec $STACK_NAME contracts001 "echo 'export ETH_RPC_URL=http://el-1-geth-lighthouse:8545' >> /commands.sh"
kurtosis service exec $STACK_NAME contracts001 "echo 'ROLLUP_MAN=\$(cat deployment/deploy_output.json  | jq -r .polygonRollupManagerAddress)' >> /commands.sh"
kurtosis service exec $STACK_NAME contracts001 "echo 'ROLLUP=\$(cat deployment/create_rollup_output.json | jq -r .rollupAddress)' >> /commands.sh"
kurtosis service exec $STACK_NAME contracts001 "echo 'GENESIS=\$(cat deployment/create_rollup_output.json  | jq -r .genesis)' >> /commands.sh"
kurtosis service exec $STACK_NAME contracts001 "echo \"CONSENSUS=\\\$(cast call \\\$ROLLUP_MAN 'rollupTypeMap(uint32)(address,address,uint64,uint8,bool,bytes32)' 1 | head -1)\" >> /commands.sh"
kurtosis service exec $STACK_NAME contracts001 "echo PRIV_KEY=0x42b6e34dc21598a807dc19d7784c71b2a7a01f6480dc6f58258f78e539f1a1fa >> /commands.sh"
kurtosis service exec $STACK_NAME contracts001 "chmod +x /commands.sh"

# wait for batches to be verified on sequencer
DONE=0
while [ $DONE -ne 1 ]; do
    TRUSTED__ON_SEQCR=$(printf "%d" $(cast rpc --json --rpc-url $(kurtosis port print $STACK_NAME sequencer001 sequencer8123) zkevm_batchNumber | jq -r))
    VERIFIED_ON_SEQCR=$(printf "%d" $(cast rpc --json --rpc-url $(kurtosis port print $STACK_NAME sequencer001 sequencer8123) zkevm_verifiedBatchNumber | jq -r))
    VERIFIED_ON_CHAIN=$(kurtosis service exec $STACK_NAME contracts001 ". /commands.sh && cast call \$ROLLUP_MAN \"rollupIDToRollupData(uint32)(address,uint64,address,uint64,bytes32,uint64,uint64,uint64,uint64,uint64,uint64,uint8)\" 1 | head -6 | tail -1" | tail -2 | head -1)
    echo "Trusted batch number on sequencer: $TRUSTED__ON_SEQCR, Verified batch number on sequencer: $VERIFIED_ON_SEQCR, Verified batch number on chain: $VERIFIED_ON_CHAIN"
    if [ "$TRUSTED__ON_SEQCR" -ne "$VERIFIED_ON_SEQCR" ] || [ "$TRUSTED__ON_SEQCR" -ne "$VERIFIED_ON_CHAIN" ]; then
        sleep 3
    else
        DONE=1
    fi
done

# wait for rpc to sync
DONE=0
while [ $DONE -ne 1 ]; do
    TRUSTED__ON_RPC=$(printf "%d" $(cast rpc --json --rpc-url $(kurtosis port print $STACK_NAME rpc001 rpc8123) zkevm_batchNumber | jq -r))
    VERIFIED_ON_RPC=$(printf "%d" $(cast rpc --json --rpc-url $(kurtosis port print $STACK_NAME rpc001 rpc8123) zkevm_verifiedBatchNumber | jq -r))
    VERIFIED_ON_CHAIN=$(kurtosis service exec $STACK_NAME contracts001 ". /commands.sh && cast call \$ROLLUP_MAN \"rollupIDToRollupData(uint32)(address,uint64,address,uint64,bytes32,uint64,uint64,uint64,uint64,uint64,uint64,uint8)\" 1 | head -6 | tail -1" | tail -2 | head -1)
    echo "Trusted batch number on rpc: $TRUSTED__ON_RPC, Verified batch number on rpc: $VERIFIED_ON_RPC, Verified batch number on chain: $VERIFIED_ON_CHAIN"
    if [ "$TRUSTED__ON_RPC" -ne "$VERIFIED_ON_RPC" ] || [ "$TRUSTED__ON_RPC" -ne "$VERIFIED_ON_CHAIN" ]; then
        sleep 3
    else
        DONE=1
    fi
done

# Stop services
kurtosis service stop $STACK_NAME cdknode001
kurtosis service stop $STACK_NAME mockprover001 
kurtosis service stop $STACK_NAME bridge001 
kurtosis service stop $STACK_NAME rpc001 
kurtosis service stop $STACK_NAME sequencer001 
kurtosis service stop $STACK_NAME executor001 

# Depoly verifier
kurtosis service exec $STACK_NAME contracts001 \
    ". /commands.sh && \
    forge create \
    --broadcast \
    --json \
    --private-key \$PRIV_KEY \
    /app/contracts/forkid$TARGET_FORKID/contracts/mocks/VerifierRollupHelperMock.sol:VerifierRollupHelperMock > verifier-out.json"

# Add new rollup type
kurtosis service exec $STACK_NAME contracts001 \
    ". /commands.sh && \
    cast send \
    --json \
    --private-key \$PRIV_KEY \
    \$ROLLUP_MAN \
    'addNewRollupType(address,address,uint64,uint8,bytes32,string)' \
    \$CONSENSUS \
    \"\$(jq -r '.deployedTo' verifier-out.json)\" \
    $TARGET_FORKID 0 \$GENESIS 'new_forkid_$TARGET_FORKID' > add-rollup-type-out.json"


# Update rollup
kurtosis service exec $STACK_NAME contracts001 \
    ". /commands.sh && \
    cast send \
    --json \
    --private-key \$PRIV_KEY \
    \$ROLLUP_MAN \
    'updateRollup(address,uint32,bytes)' \
    \$ROLLUP \
    \$(printf \"%d\\n\" \$(jq -r '.logs[0].topics[1]' add-rollup-type-out.json)) \
    0x > update-rollup-type-out.json"

# Verify forkid on chain
FORKID_ON_CHAIN=$(kurtosis service exec $STACK_NAME contracts001 ". /commands.sh && cast call \$ROLLUP_MAN \"rollupIDToRollupData(uint32)(address,uint64,address,uint64,bytes32,uint64,uint64,uint64,uint64,uint64,uint64,uint8)\" 1 | head -4 | tail -1" | tail -2 | head -1)
if [ "$FORKID_ON_CHAIN" -ne $TARGET_FORKID ]; then
    echo "Forkid not updated on chain"
    exit 1
else
    echo "Forkid updated on chain: $FORKID_ON_CHAIN"
fi

# Update zkprover image for new forkid
ZKPROVER=$(jq -r .zkProver.image forkid${TARGET_FORKID}.json)

jq --arg zkprover "$ZKPROVER" '.zkProver.image = $zkprover' $KURTOSIS_CONFIG > ${KURTOSIS_CONFIG}.new
jq --arg forkid $TARGET_FORKID '.l1.deploy = false | .contracts.deploy = false | .contracts.rollup_fork_id = $forkid' ${KURTOSIS_CONFIG}.new > $KURTOSIS_CONFIG
rm ${KURTOSIS_CONFIG}.new

kurtosis service stop $STACK_NAME cdknode001
kurtosis service start $STACK_NAME cdknode001
kurtosis service exec $STACK_NAME cdknode001 "sed -i 's/ForkId = '$SOURCE_FORKID'/ForkId = '$TARGET_FORKID'/' /config/cdknode-config.toml"
kurtosis service stop $STACK_NAME cdknode001

kurtosis run --enclave $STACK_NAME . '{"config": "'$KURTOSIS_CONFIG'"}'

# Wait for TARGET_BATCH to be verified
TARGET_BATCH=$((VERIFIED_ON_CHAIN+5))
DONE=0
while [ $DONE -ne 1 ]; do
    TRUSTED__ON_RPC=$(printf "%d" $(cast rpc --json --rpc-url $(kurtosis port print $STACK_NAME rpc001 rpc8123) zkevm_batchNumber | jq -r))
    VERIFIED_ON_RPC=$(printf "%d" $(cast rpc --json --rpc-url $(kurtosis port print $STACK_NAME rpc001 rpc8123) zkevm_verifiedBatchNumber | jq -r))
    VERIFIED_ON_CHAIN=$(kurtosis service exec $STACK_NAME contracts001 ". /commands.sh && cast call \$ROLLUP_MAN \"rollupIDToRollupData(uint32)(address,uint64,address,uint64,bytes32,uint64,uint64,uint64,uint64,uint64,uint64,uint8)\" 1 | head -6 | tail -1" | tail -2 | head -1)
    echo "Target: $TARGET_BATCH | Trusted batch number on rpc: $TRUSTED__ON_RPC, Verified batch number on rpc: $VERIFIED_ON_RPC, Verified batch number on chain: $VERIFIED_ON_CHAIN"
    if [ "$TRUSTED__ON_RPC" -lt "$TARGET_BATCH" ] || [ "$VERIFIED_ON_RPC" -lt "$TARGET_BATCH" ] || [ "$VERIFIED_ON_CHAIN" -lt "$TARGET_BATCH" ]; then
        sleep 3
    else
        DONE=1
    fi
done

# clean up
# cd $REPO_FOLDER
# rm $KURTOSIS_CONFIG
