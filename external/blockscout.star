blockscout_package = import_module(
    "github.com/xavier-romero/kurtosis-blockscout/main.star"
)


def run(plan, args):
    # Start blockscout.
    blockscout_package.run(
        plan,
        args={
            "rpc_url": args["l2_rpc_url"],
            "trace_url": args["l2_rpc_url"],
            "ws_url": args["l2_ws_url"],
            "chain_id": str(args["l2_chain_id"]),
            "deployment_suffix": args["deployment_suffix"],
        },
    )
