def _generate_config_file(plan, cfg, service):
    # Config file
    cfg_filename = cfg["COMMON"]["CONFIG_FILE"]
    cfg_template = "./config/erigon-config.yaml"

    cfg_file_tpl = read_file(src=cfg_template)

    plan.render_templates(
        name="erigon-" + service + "-" + cfg_filename,
        config={cfg_filename: struct(template=cfg_file_tpl, data=cfg)},
    )


def _generate_dynamic_files(plan, cfg):
    # Dynamic config files
    dyn_script = "./scripts/generate_dynamic_files.py"

    script = read_file(src=dyn_script)
    result = plan.run_python(
        run=script,
        args=[str(cfg["l2_chain_id"])],
        files={
            # These artifacts match with contracts.ARTIFACTS_TO_SAVE
            "/input/genesis": plan.get_files_artifact("genesis.json"),
            "/input/rollup_output": plan.get_files_artifact(
                "create_rollup_output.json"
            ),
        },
        store=[
            StoreSpec(
                src="/tmp/dynamic-cdk-allocs.json", name="erigon-dynamic-cdk-allocs"
            ),
            StoreSpec(src="/tmp/dynamic-cdk-conf.json", name="erigon-dynamic-cdk-conf"),
            StoreSpec(
                src="/tmp/dynamic-cdk-chainspec.json",
                name="erigon-dynamic-cdk-chainspec",
            ),
        ],
    )


def _get_genesis_params(plan):
    # Retrieve specific genesis parameters
    genesis_params = {}
    for k, param in (
        ("rollupAddress", "polygonRollupManagerAddress"),
        ("zkevmAddress", "polygonZkEVMAddress"),
        ("gerAddress", "polygonZkEVMGlobalExitRootAddress"),
        ("polAddress", "polTokenAddress"),
    ):
        result = plan.run_sh(
            run="jq -j .l1Config." + param + " /input/genesis.json",
            files={"/input": plan.get_files_artifact("genesis.json")},
        )
        genesis_params[k] = result.output.strip()

    result = plan.run_sh(
        run="jq -j .createRollupBlockNumber /input/create_rollup_output.json",
        files={"/input": plan.get_files_artifact("create_rollup_output.json")},
    )
    genesis_params["rollupBlockNumber"] = result.output.strip()

    return genesis_params


def _deploy_service(plan, cfg, service):
    service_ports = cfg[service]["PORTS"]
    service_name = cfg[service]["NAME"]
    service_image = cfg[service]["IMAGE"]
    service_cmd = cfg[service]["CMD"]
    service_vars = cfg[service]["ENV_VARS"]

    cfg_filename = cfg["COMMON"]["CONFIG_FILE"]
    cfg_path = cfg["COMMON"]["CONFIG_PATH"]

    service_config = ServiceConfig(
        image=service_image,
        ports={
            "{}-{}".format(service_name, service_port): PortSpec(
                service_port, application_protocol="http", wait="20s"
            )
            for service_port in service_ports
        },
        env_vars=service_vars,
        files={
            cfg_path: Directory(
                artifact_names=[
                    plan.get_files_artifact("erigon-" + service + "-" + cfg_filename),
                    plan.get_files_artifact("erigon-dynamic-cdk-allocs"),
                    plan.get_files_artifact("erigon-dynamic-cdk-conf"),
                    plan.get_files_artifact("erigon-dynamic-cdk-chainspec"),
                ]
            )
            # cfg_path: plan.get_files_artifact("erigon-" + service + "-" + cfg_filename),
            # "/etc/erigon/dynamic-configs": Directory(
            #     artifact_names=[
            #         plan.get_files_artifact("erigon-dynamic-cdk-allocs"),
            #         plan.get_files_artifact("erigon-dynamic-cdk-conf"),
            #         plan.get_files_artifact("erigon-dynamic-cdk-chainspec"),
            #     ]
            # ),
            # "/datadir": Directory(persistent_key="erigon-{}-datadir".format(service.lower())),
        },
        cmd=service_cmd,
        # Temporary solution to avoid permission issues on datadir
        # Erigon by defaults uses user 1000:1000 so we would need to set the folder perms
        user=User(uid=0, gid=0),
    )

    service = plan.add_service(
        name=service_name,
        config=service_config,
        description="Adding service {}".format(service_name),
    )

    return service


def run(plan, cfg):
    plan.print("Generating Erigon config files")
    _generate_dynamic_files(plan, cfg)

    gen_params = _get_genesis_params(plan)

    plan.print("Deploying Erigon Sequencer")
    service = "SEQUENCER"
    sequencer_cfg = (
        cfg
        | gen_params
        | {
            "seq_rpc": "http://127.0.0.1:{}".format(cfg["sequencer_rpc_port"]),
            "seq_ds": "127.0.0.1:{}".format(cfg["sequencer_ds_port"]),
        }
    )
    _generate_config_file(plan, sequencer_cfg, service)
    sequencer_service = _deploy_service(plan, sequencer_cfg, service)

    plan.print("Deploying Erigon RPC")
    service = "RPC"
    sequencer_rpc = "http://{}:{}".format(
        sequencer_service.ip_address, cfg["SEQUENCER"]["PORTS"][0]
    )
    sequencer_ds = "{}:{}".format(
        sequencer_service.ip_address, cfg["SEQUENCER"]["PORTS"][1]
    )
    plan.print("Sequencer RPC: {}".format(sequencer_rpc))
    plan.print("Sequencer DS: {}".format(sequencer_ds))
    rpc_cfg = cfg | gen_params | {"seq_rpc": sequencer_rpc, "seq_ds": sequencer_ds}
    _generate_config_file(plan, rpc_cfg, service)
    rpc_service = _deploy_service(plan, rpc_cfg, "RPC")

    return sequencer_service, rpc_service
