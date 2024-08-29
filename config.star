_PARAMS_FILE = "params.json"
_RPC_HTTP_PORT = 8123
_DAC_PORT = 8484
_AGGR_PORT = 50081
_L1_FUNDING_AMOUNT = "100ether"
_SEQUENCER_RPC_PORT = 8123
_SEQUENCER_DS_PORT = 6900
_EXECUTOR_PORT = 50071


def _get_erigon_config(cfg):
    ERIGON_COMMON = {
        "IMAGE": cfg.get("image"),
        "CONFIG_PATH": "/etc/erigon",
        "CONFIG_FILE": "config.yaml",
    }

    ERIGON = {
        "SEQUENCER": {
            "NAME": "sequencer",
            "IMAGE": ERIGON_COMMON["IMAGE"],
            "CMD": [
                "--config",
                ERIGON_COMMON["CONFIG_PATH"] + "/" + ERIGON_COMMON["CONFIG_FILE"],
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
                "--config",
                ERIGON_COMMON["CONFIG_PATH"] + "/" + ERIGON_COMMON["CONFIG_FILE"],
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
        "aggregator_port": _AGGR_PORT,
        "sequencer_rpc_port": _SEQUENCER_RPC_PORT,
        "sequencer_ds_port": _SEQUENCER_DS_PORT,
        "executor_port": _EXECUTOR_PORT,
    }
    if args.get("erigon"):
        cfg["erigon"] = _get_erigon_config(args.get("erigon"))
        cfg["erigon"]["l2_chain_id"] = args["contracts"]["l2_chain_id"]
        cfg["erigon"]["l1_chain_id"] = args["l1"]["chain_id"]
        cfg["erigon"]["l1_rpc_url"] = args["contracts"]["l1_rpc_url"]
        cfg["erigon"]["fork_id"] = args["contracts"]["rollup_fork_id"]

    return args | cfg
