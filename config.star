_PARAMS_FILE = "params.json"
_RPC_HTTP_PORT = 8123
_DAC_PORT = 8484
_AGGR_PORT = 50081
_L1_FUNDING_AMOUNT = 100
_SEQUENCER_RPC_PORT = 8123
_SEQUENCER_DS_PORT = 6900
_EXECUTOR_PORT = 50071


def _get_erigon_config(cfg):
    ERIGON_COMMON = {
        "IMAGE": cfg.get("image"),
        "CONFIG_PATH": "/etc/erigon",
        "DATADIR_PATH": "/datadir",
    }

    ERIGON = {
        "SEQUENCER": {
            "NAME": "sequencer",
            "IMAGE": ERIGON_COMMON["IMAGE"],
            "CMD": [
                "--pprof",
                "--config",
                ERIGON_COMMON["CONFIG_PATH"] + "/erigon-sequencer.yaml",
            ],
            "PORTS": [_SEQUENCER_RPC_PORT, _SEQUENCER_DS_PORT],
            "ENV_VARS": {
                "CDK_ERIGON_SEQUENCER": "1",
            },
        },
        "RPC": {
            "NAME": "rpc",
            "IMAGE": ERIGON_COMMON["IMAGE"],
            "CMD": [
                "--pprof",
                "--config",
                ERIGON_COMMON["CONFIG_PATH"] + "/erigon-rpc.yaml",
            ],
            "PORTS": [_SEQUENCER_RPC_PORT, _SEQUENCER_DS_PORT],
            "ENV_VARS": {},
        },
    }
    return ERIGON | {"COMMON": ERIGON_COMMON}


def get_config(args):
    params = read_file(src=_PARAMS_FILE)
    args = json.decode(params) | args

    cfg = {
        # "suffix": args.get("deployment_suffix")
        # and "-" + args["deployment_suffix"]
        # or "",
        "zkevm_rpc_http_port": _RPC_HTTP_PORT,
        "zkevm_dac_port": _DAC_PORT,
        "l1_funding_amount": _L1_FUNDING_AMOUNT,
        "sequencer_rpc_port": _SEQUENCER_RPC_PORT,
        "sequencer_ds_port": _SEQUENCER_DS_PORT,
    }

    for k in args.keys():
        if type(args[k]) == type({}):
            args[k]["deployment_suffix"] = args.get("deployment_suffix")

    if args.get("erigon"):
        cfg["erigon"] = _get_erigon_config(args.get("erigon"))
        cfg["erigon"]["l2_chain_id"] = args["contracts"]["l2_chain_id"]
        cfg["erigon"]["l1_chain_id"] = args["l1"]["chain_id"]
        cfg["erigon"]["l1_rpc_url"] = args["contracts"]["l1_rpc_url"]
        cfg["erigon"]["fork_id"] = args["contracts"]["rollup_fork_id"]
        cfg["erigon"]["deployment_suffix"] = args.get("deployment_suffix")

    if args.get("aggregator"):
        cfg["aggregator"] = args.get("aggregator")
        cfg["aggregator"]["aggregator_port"] = _AGGR_PORT

    if args.get("executor"):
        cfg["executor"] = args.get("executor")
        cfg["executor"]["executor_port"] = _EXECUTOR_PORT

    if args.get("dac"):
        cfg["dac"] = args.get("dac")
        cfg["dac"]["dac_port"] = _DAC_PORT

    return args | cfg
