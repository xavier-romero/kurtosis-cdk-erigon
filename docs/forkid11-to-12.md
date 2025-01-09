# Upgrade Forkid11 to Forkid12 for zkEVM Rollup

## Steps

1. Deploy rollup with forkid 11
```bash
kurtosis run --enclave cdk . '{"config": "forkid11.json"}'
```

2. Send a test transaction
```bash
PRIV_KEY=0x42b6e34dc21598a807dc19d7784c71b2a7a01f6480dc6f58258f78e539f1a1fa
cast send --rpc-url $(kurtosis port print cdk rpc001 rpc8123) --legacy --private-key $PRIV_KEY --value 0.01ether 0x0000000000000000000000000000000000000000
```

3. Halt Sequencer
Get into sequencer and add param to halt on near batch:
```bash
kurtosis service shell cdk sequencer001
HALTON=$(printf "%d\n" $(($(curl -s -X POST -H "Content-Type: application/json" -d '{"method":"zkevm_batchNumber","id":1,"jsonrpc":"2.0"}' http://localhost:8123 | jq -r .result)+5)))
echo "zkevm.sequencer-halt-on-batch-number: $HALTON" >> /etc/erigon/erigon-sequencer.yaml
```
Stop and start sequencer with that new config:
```bash
kurtosis service stop cdk sequencer001
kurtosis service start cdk sequencer001
```
At some point you should see that log on sequencer:
```bash
[INFO] [01-09|10:30:42.395] [5/13 Execution] Halt sequencer on batch 205... 
```

4. Wait for bath and verified to be the same, and just 1 behind virtual

NOTE: This never happens unless you reconfigure CDKNODE to point to Sequencer instead RPC....
```bash
cast rpc --rpc-url $(kurtosis port print cdk sequencer001 sequencer8123) zkevm_batchNumber
cast rpc --rpc-url $(kurtosis port print cdk sequencer001 sequencer8123) zkevm_virtualBatchNumber
cast rpc --rpc-url $(kurtosis port print cdk sequencer001 sequencer8123) zkevm_verifiedBatchNumber
```

5. Stop critical services
```bash
kurtosis service stop cdk cdknode001 
kurtosis service stop cdk mockprover001 
kurtosis service stop cdk bridge001 
kurtosis service stop cdk rpc001 
kurtosis service stop cdk sequencer001 
kurtosis service stop cdk executor001 
```

6. Get into contracts service and set up required vars
```bash
kurtosis service shell cdk contracts001
cd /output
export ETH_RPC_URL=http://el-1-geth-lighthouse:8545
ROLLUP_MAN=$(cat deployment/deploy_output.json  | jq -r .polygonRollupManagerAddress)
CONSENSUS=$(cast call $ROLLUP_MAN 'rollupTypeMap(uint32)(address,address,uint64,uint8,bool,bytes32)' 1 | head -1)
GENESIS=$(cat deployment/create_rollup_output.json  | jq -r .genesis)
PRIV_KEY=0x42b6e34dc21598a807dc19d7784c71b2a7a01f6480dc6f58258f78e539f1a1fa
ROLLUP=$(cat deployment/create_rollup_output.json | jq -r .rollupAddress)
```

7. Deploy new verifier

That's not really needed since the Mock Verifier is the same for 11 and 12, but just to show the whole process.
```bash
forge create \
    --broadcast \
    --json \
    --private-key $PRIV_KEY \
    /app/contracts/forkid12/contracts/mocks/VerifierRollupHelperMock.sol:VerifierRollupHelperMock > verifier-out.json
```

8. Create new RollupType for forkid 12
```bash
cast send \
    --json \
    --private-key $PRIV_KEY \
    $ROLLUP_MAN \
    'addNewRollupType(address,address,uint64,uint8,bytes32,string)' \
    $CONSENSUS \
    "$(jq -r '.deployedTo' verifier-out.json)" \
    12 0 $GENESIS 'new_forkid_12' > add-rollup-type-out.json
NEW_ROLLUP_TYPE_ID=$(printf "%d\n" $(jq -r '.logs[0].topics[1]' add-rollup-type-out.json))
```

9. Update your rollup to 12
```bash
cast send \
    --json \
    --private-key $PRIV_KEY \
    $ROLLUP_MAN \
    'updateRollup(address,uint32,bytes)' \
    $ROLLUP $NEW_ROLLUP_TYPE_ID 0x > update-rollup-type-out.json
```

10. Verify forkid 12 on chain
```bash
cast call $ROLLUP_MAN \
    "rollupIDToRollupData(uint32)(address,uint64,address,uint64,bytes32,uint64,uint64,uint64,uint64,uint64,uint64,uint8)" 1 \
    | head -4 | tail -1
```
