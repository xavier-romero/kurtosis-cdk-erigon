_RPC_HTTP_PORT = 8123
_DAC_PORT = 8484
_L1_FUNDING_AMOUNT = "100ether"


def _get_erigon_config(cfg):
    ERIGON_COMMON = {
        "IMAGE": cfg.get("image"),
        "CONFIG_PATH": "/etc/erigon",
        "CONFIG_FILE": "config.yaml",
    }

    ERIGON = {
        "SEQUENCER": {
            "NAME": "erigon-sequencer",
            "IMAGE": ERIGON_COMMON["IMAGE"],
            "CMD": [
                "--config",
                ERIGON_COMMON["CONFIG_PATH"] + "/" + ERIGON_COMMON["CONFIG_FILE"],
            ],
            "PORTS": [8123, 6900],
            "ENV_VARS": {
                "CDK_ERIGON_SEQUENCER": "1",
            },
        },
        "RPC": {
            "NAME": "erigon-rpc",
            "IMAGE": ERIGON_COMMON["IMAGE"],
            "CMD": [
                "--config",
                ERIGON_COMMON["CONFIG_PATH"] + "/" + ERIGON_COMMON["CONFIG_FILE"],
            ],
            "PORTS": [8123, 6900],
            "ENV_VARS": {},
        },
    }
    return ERIGON | {"COMMON": ERIGON_COMMON}


def get_config(args):
    cfg = {
        "suffix": args.get("deployment_suffix")
        and "-" + args["deployment_suffix"]
        or "",
        "zkevm_rpc_http_port": _RPC_HTTP_PORT,
        "zkevm_dac_port": _DAC_PORT,
        "l1_funding_amount": _L1_FUNDING_AMOUNT,
    }
    if args.get("erigon"):
        cfg["erigon"] = _get_erigon_config(args.get("erigon"))
        cfg["erigon"]["l2_chain_id"] = args["contracts"]["l2_chain_id"]
        cfg["erigon"]["l1_chain_id"] = args["l1"]["chain_id"]
        cfg["erigon"]["l1_rpc_url"] = args["contracts"]["l1_rpc_url"]
        cfg["erigon"]["fork_id"] = args["contracts"]["rollup_fork_id"]

    return args | cfg
