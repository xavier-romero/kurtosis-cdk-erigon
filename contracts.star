ARTIFACTS_TO_SAVE = {
    "path": "/output",
    # These files are used from erigon._generate_dynamic_files, ssender, aggregator
    "files": [
        "aggregator-config.toml",
        "aggregator.keystore",
        "claimtx.keystore",
        "create_rollup_output.json",
        "create_rollup_parameters.json",
        "dac-config.toml",
        "deploy_output.json",
        "deploy_parameters.json",
        "erigon-sequencer.yaml",
        "erigon-rpc.yaml",
        "executor-config.json",
        "genesis.json",
        "dynamic-kurtosis-allocs.json",
        "dynamic-kurtosis-conf.json",
        "dynamic-kurtosis-chainspec.json",
        "kurtosis-chainspec.json",
        "mockprover-config.json",
        "sequencer.keystore",
        "ssender-config.toml",
        "network-kurtosis.json",
        "wallets.json",
    ],
}


def run(plan, cfg):
    contracts_service_name = "contracts" + cfg["suffix"]
    contracts_image = cfg["image"]
    plan.add_service(
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
                "L2_CHAIN_ID": str(cfg["l2_chain_id"]),
                "IS_VALIDIUM": "1" if cfg.get("validium") else "0",
                "L1_FUND_AMOUNT": str(cfg["l1_funding_amount"]),
                "JSON_EXTRA_PARAMS": json.encode(cfg.get("extra", {}))
            }
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

    for artifact_to_save in ARTIFACTS_TO_SAVE["files"]:
        plan.print(type(artifact_to_save))
        # No isinstance availble for Starlark :-<
        if type(artifact_to_save) == type({}):
            (src, dst) = list(artifact_to_save.items())[0]
        else:
            src = artifact_to_save
            dst = artifact_to_save

        plan.store_service_files(
            service_name=contracts_service_name,
            name=dst,
            src="{}/{}".format(ARTIFACTS_TO_SAVE["path"], src),
            description="Storing {}".format(dst),
        )
