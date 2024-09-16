CONTRACTS_CONFIG = {
    "artifacts": [
        {
            "name": "deploy_parameters.json",
            "file": "./contracts/deploy_parameters.json",
        },
        {
            "name": "create_rollup_parameters.json",
            "file": "./contracts/create_rollup_parameters.json",
        },
        {
            "name": "run-contract-setup.sh",
            "file": "./contracts/run-contract-setup.sh",
        },
        {
            "name": "create-keystores.sh",
            "file": "./contracts/create-keystores.sh",
        },
    ]
}

ARTIFACTS_TO_SAVE = {
    "path": "/opt/zkevm",
    # These files are used from erigon._generate_dynamic_files, ssender, aggregator
    "files": [
        "create_rollup_output.json",
        "deploy_output.json",
        "genesis.json",
        "sequencer.keystore",
        "aggregator.keystore",
        "dac.keystore",
    ],
}


def run(plan, cfg):
    contracts_service_name = "contracts" + cfg["suffix"]
    contracts_image = cfg["image"]
    plan.add_service(
        name=contracts_service_name,
        config=ServiceConfig(
            image=contracts_image,
            files={
                "/output": Directory(persistent_key="contracts-output")
            },
            user=User(uid=0, gid=0),  # Run the container as root user.
            env_vars={
                'START': "0",
                'L1_RPC_URL': cfg['l1_rpc_url'],
                'L1_FUNDED_MNEMONIC': cfg['l1_funded_mnemonic'],
                'FORKID': str(cfg['rollup_fork_id']),
                'REAL_VERIFIER': "0",
                'NETWORK_NAME': 'kurtosis',
                'L2_CHAIN_ID': str(cfg['l2_chain_id']),
                'IS_VALIDIUM': "1" if cfg.get('validium') else "0",
                'L1_FUND_AMOUNT': str(cfg['l1_funding_amount']),
            }
        )
    )

    plan.exec(
        description="Executing contract deployment",
        service_name=contracts_service_name,
        acceptable_codes=[0],
        recipe=ExecRecipe(
            command=["bash", "-c", "START=1; python3 -u /app/app.py"],
        ),
    )


    # artifacts = []
    # for artifact_cfg in CONTRACTS_CONFIG["artifacts"]:
    #     template = read_file(src=artifact_cfg["file"])
    #     artifact = plan.render_templates(
    #         name=artifact_cfg["name"],
    #         config={artifact_cfg["name"]: struct(template=template, data=cfg)},
    #     )
    #     artifacts.append(artifact)

    # # Create helper service to deploy contracts
    # contracts_service_name = "contracts" + cfg["deployment_suffix"]
    # zkevm_contracts_image = "{}:fork{}".format(cfg["image"], cfg["rollup_fork_id"])
    # plan.add_service(
    #     name=contracts_service_name,
    #     config=ServiceConfig(
    #         image=zkevm_contracts_image,
    #         files={
    #             "/opt/zkevm": Directory(persistent_key="zkevm-artifacts"),
    #             "/opt/contract-deploy/": Directory(artifact_names=artifacts),
    #         },
    #         # These two lines are only necessary to deploy to any Kubernetes environment (e.g. GKE).
    #         entrypoint=["bash", "-c"],
    #         cmd=["sleep infinity"],
    #         user=User(uid=0, gid=0),  # Run the container as root user.
    #     ),
    # )

    # # TODO: Check if the contracts were already initialized.. I'm leaving this here for now, but it's not useful!!
    # contract_init_stat = plan.exec(
    #     description="Checking if contracts are already initialized",
    #     service_name=contracts_service_name,
    #     acceptable_codes=[0, 1],
    #     recipe=ExecRecipe(command=["stat", "/opt/zkevm/.init-complete.lock"]),
    # )

    # # Deploy contracts.
    # plan.exec(
    #     description="Deploying zkevm contracts on L1",
    #     service_name=contracts_service_name,
    #     recipe=ExecRecipe(
    #         command=[
    #             "/bin/sh",
    #             "-c",
    #             "chmod +x {0} && {0}".format(
    #                 "/opt/contract-deploy/run-contract-setup.sh"
    #             ),
    #         ]
    #     ),
    # )

    # # Create keystores.
    # plan.exec(
    #     description="Creating keystores for zkevm-node/cdk-validium components",
    #     service_name=contracts_service_name,
    #     recipe=ExecRecipe(
    #         command=[
    #             "/bin/sh",
    #             "-c",
    #             "chmod +x {0} && {0}".format(
    #                 "/opt/contract-deploy/create-keystores.sh"
    #             ),
    #         ]
    #     ),
    # )

    # for artifact_to_save in ARTIFACTS_TO_SAVE["files"]:
    #     plan.store_service_files(
    #         service_name=contracts_service_name,
    #         src="{}/{}".format(ARTIFACTS_TO_SAVE["path"], artifact_to_save),
    #         name=artifact_to_save,
    #         description="Storing {}".format(artifact_to_save),
    #     )
