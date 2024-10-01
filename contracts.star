ARTIFACTS_TO_SAVE = {
    "path": "/output",
    # These files are used from erigon._generate_dynamic_files, ssender, aggregator
    "files": [
        # Configuration files
        "config/aggregator-config.toml",
        "config/erigon-sequencer.yaml",
        "config/erigon-rpc.yaml",
        "config/executor-config.json",
        "config/dynamic-kurtosis-allocs.json",
        "config/dynamic-kurtosis-conf.json",
        "config/dynamic-kurtosis-chainspec.json",
        "config/mockprover-config.json",
        "config/ssender-config.toml",
        "config/pool-manager-config.toml",
        "config/bridge-config.toml",
        "config/node-genesis.json",
        # Keystores
        "config/keystores/aggregator.keystore",
        "config/keystores/claimtxmanager.keystore",
        "config/keystores/sequencer.keystore",
        # Deployment files
        "deployment/create_rollup_output.json",
        "deployment/create_rollup_parameters.json",
        "deployment/deploy_output.json",
        "deployment/deploy_parameters.json",
        "deployment/genesis.json",
        "deployment/network-kurtosis.json",
        # Accounts/wallets info
        "wallets.json",
    ],
}
DAC_ARTIFACTS_TO_SAVE = [
    "/config/keystores/dac.keystore",
    "/config/dac-config.toml",
]


def run(plan, cfg):
    contracts_service_name = "contracts" + cfg["deployment_suffix"]
    contracts_image = cfg["image"]
    service = plan.add_service(
        name=contracts_service_name,
        config=ServiceConfig(
            image=contracts_image,
            files={"/output": Directory(persistent_key="contracts-output")},
            user=User(uid=0, gid=0),  # Run the container as root user.
            env_vars={
                "START": "0",
                "L1_RPC_URL": cfg["l1_rpc_url"],
                "L1_FUNDED_MNEMONIC": cfg["l1_funded_mnemonic"],
                "FORKID": str(cfg["rollup_fork_id"]),
                "REAL_VERIFIER": "0",
                "NETWORK_NAME": "kurtosis",
                "DEPLOY_GAS_TOKEN": "1" if cfg["deploy_gas_token"] else "0",
                "L2_CHAIN_ID": str(cfg["l2_chain_id"]),
                "IS_VALIDIUM": "1" if cfg.get("validium") else "0",
                "L1_FUND_AMOUNT": str(cfg["l1_funding_amount"]),
                "ADDRESSES": json.encode(cfg.get("addresses", {})),
                "DAC_URLS": cfg.get("dac_urls", ""),
                "COMPOSE_CONFIG": "0",
                "JSON_EXTRA_PARAMS": json.encode(cfg.get("extra", {})),
            },
        ),
    )
    plan.exec(
        description="Executing contract deployment",
        service_name=contracts_service_name,
        acceptable_codes=[0],
        recipe=ExecRecipe(
            command=["bash", "-c", "START=1; python3 -u /app/app.py"],
        ),
    )

    _artifacts_to_save = ARTIFACTS_TO_SAVE["files"]
    if cfg.get("validium"):
        _artifacts_to_save = ARTIFACTS_TO_SAVE["files"] + DAC_ARTIFACTS_TO_SAVE

    for artifact_to_save in _artifacts_to_save:
        if type(artifact_to_save) == type("string"):
            src = artifact_to_save
            dst = artifact_to_save.split("/")[-1]
        # No isinstance availble for Starlark :-<
        elif type(artifact_to_save) == type({}):
            (src, dst) = list(artifact_to_save.items())[0]
        else:
            fail("Invalid artifact_to_save: {}".format(artifact_to_save))

        plan.store_service_files(
            service_name=contracts_service_name,
            name=dst,
            src="{}/{}".format(ARTIFACTS_TO_SAVE["path"], src),
            description="Storing {}".format(dst),
        )

    return service
