blockscout_package = import_module(
    "github.com/xavier-romero/kurtosis-blockscout/main.star"
)


def run(plan):
    # Start blockscout.
    blockscout_package.run(
        plan,
        args={
            "blockscout_public_port": 7766,
            "rpc_url": "http://el-1-geth-lighthouse:8545",
            "trace_url": "http://el-1-geth-lighthouse:8545",
            "ws_url": "ws://el-1-geth-lighthouse:8546",
            "chain_id": "271828",
        },
    )
