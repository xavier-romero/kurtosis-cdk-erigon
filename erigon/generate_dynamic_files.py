import json
import sys

l2_chain_id = int(sys.argv[1])

genesis_file = "/input/genesis/genesis.json"
rollup_output_file = "/input/rollup_output/create_rollup_output.json"

erigon_dyn_allocs_file = "/tmp/dynamic-cdk-allocs.json"
erigon_dyn_conf_file = "/tmp/dynamic-cdk-conf.json"
erigon_dyn_chainspec_file = "/tmp/dynamic-cdk-chainspec.json"


g = open(genesis_file)
ro = open(rollup_output_file)
deployment_genesis = json.load(g)
rollup_output = json.load(ro)

erigon_dyn_allocs = {}
genesis = deployment_genesis.get('genesis')
for x in genesis:
    _item = {
        'contractName': x.get('contractName'),
        'balance': x.get('balance'),
        'nonce': x.get('nonce'),
        'code': x.get('bytecode'),
        'storage': x.get('storage')
    }
    erigon_dyn_allocs[x.get('address')] = _item

erigon_dyn_conf = {
    'root': deployment_genesis.get('root'),
    'timestamp': rollup_output['firstBatchData']['timestamp'],
    'gasLimit': 0,
    'difficulty': 0
}

f = open(erigon_dyn_allocs_file, "w")
json.dump(erigon_dyn_allocs, f, indent=2)
f.close()

f = open(erigon_dyn_conf_file, "w")
json.dump(erigon_dyn_conf, f, indent=2)
f.close()

erigon_dyn_chainspec = {
    "ChainName": "dynamic-cdk",
    "chainId": l2_chain_id,
    "consensus": "ethash",
    "homesteadBlock": 0,
    "daoForkBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "muirGlacierBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 9999999999999999999999999999999999999999999999999,
    "arrowGlacierBlock": 9999999999999999999999999999999999999999999999999,
    "grayGlacierBlock": 9999999999999999999999999999999999999999999999999,
    "terminalTotalDifficulty": 58750000000000000000000,
    "terminalTotalDifficultyPassed": False,
    "shanghaiTime": 9999999999999999999999999999999999999999999999999,
    "cancunTime": 9999999999999999999999999999999999999999999999999,
    "pragueTime": 9999999999999999999999999999999999999999999999999,
    "ethash": {}
}
f = open(erigon_dyn_chainspec_file, "w")
json.dump(erigon_dyn_chainspec, f, indent=2)
f.close()

print(json.dumps({
    'rollupAddress': deployment_genesis['L1Config']['polygonRollupManagerAddress'],
    'zkevmAddress': deployment_genesis['L1Config']['polygonZkEVMAddress'],
    'gerAddress': deployment_genesis['L1Config']['polygonZkEVMGlobalExitRootAddress'],
    'polAddress': deployment_genesis['L1Config']['polTokenAddress'],
    'rollupBlockNumber': rollup_output['createRollupBlockNumber'],
}))
