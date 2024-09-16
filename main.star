config_package = "./config.star"
contracts_package = "./contracts.star"
ethereum_package = "./external/ethereum.star"
executor_package = "./components/executor.star"
erigon_package = "./components/erigon.star"
databases_package = "./components/databases.star"
aggregator_package = "./components/aggregator.star"
ssender_package = "./components/ssender.star"
mockprover_package = "./components/mockprover.star"
dac_package = "./components/dac.star"
blockscout_package = "./external/blockscout.star"


def run(plan, args):
    # Import config
    cfg = import_module(config_package).get_config(args)

    # Foo service allow to insert sleeps when needed
    foo = plan.add_service(
        name="foo" + cfg["deployment_suffix"],
        config=ServiceConfig(image="alpine:latest", cmd=["sleep", "infinity"]),
        description="Adding foo service",
    )

    # Deploy database (aggregator)
    databases = import_module(databases_package)
    databases.run(plan, suffix=cfg["deployment_suffix"])
    db_configs = databases.get_db_configs(cfg["deployment_suffix"])

    # L1 deployment
    l1_config = cfg.get("l1", {})
    if l1_config:
        import_module(ethereum_package).run(plan, l1_config)
    else:
        plan.print("Skipping the deployment of a local L1")

    contracts_config = cfg.get("contracts")
    # Deploy zkevm contracts on L1.
    if contracts_config:
        addresses = cfg.get("addresses")
        if not addresses:
            fail("Missing addresses for zkevm contracts")
        for k, v in l1_config.items():
            contracts_config["l1_" + k] = v
        contracts_config = (
            contracts_config
            | addresses
            # Wont be used if not Validium, no need to remove:
            | {
                "dac_url": "http://{}:{}".format(
                    cfg["dac"]["service_name"] + cfg["deployment_suffix"],
                    cfg["zkevm_dac_port"],
                ),
                "deployment_suffix": cfg["deployment_suffix"],
                "l1_funding_amount": cfg["l1_funding_amount"],
                "suffix": cfg["deployment_suffix"],
                "sequencer_rpc_port": cfg["sequencer_rpc_port"],
            }
        )
        plan.print("Deploying zkevm contracts on L1")
        import_module(contracts_package).run(plan, contracts_config)
    else:
        plan.print("Skipping the deployment of zkevm contracts on L1")

    # Deploy executor
    executor_config = cfg.get("executor")
    if executor_config:
        executor_config |= {
            "deployment_suffix": cfg["deployment_suffix"],
            "executor_port": cfg["executor_port"],
        }
        import_module(executor_package).run(plan, executor_config)

    # Deploy Erigon
    erigon_config = (
        cfg.get("erigon")
        | cfg.get("addresses")
        | {x: cfg[x] for x in ("sequencer_rpc_port", "sequencer_ds_port")}
        | {
            "deployment_suffix": cfg.get("deployment_suffix"),
            "stateless_executor": cfg.get("executor").get("service_name")
            + cfg.get("deployment_suffix"),
            "executor_port": cfg["executor_port"],
        }
    )
    sequencer_service, rpc_service = import_module(erigon_package).run(
        plan, erigon_config
    )
    l2_rpc_url = "http://{}:{}".format(
        rpc_service.ip_address, cfg["sequencer_rpc_port"]
    )
    l2_seq_url = "http://{}:{}".format(
        sequencer_service.ip_address, cfg["sequencer_rpc_port"]
    )

    if contracts_config.get("validium"):
        # Deploy DAC
        dac_config = cfg.get("dac")
        if dac_config:
            dac_config = (
                dac_config
                | db_configs
                | cfg.get("addresses")
                | {
                    "dac_port": cfg["zkevm_dac_port"],
                    "keystore_password": cfg["contracts"]["keystore_password"],
                    "l1_rpc_url": cfg["contracts"]["l1_rpc_url"],
                    "l1_ws_url": cfg["contracts"]["l1_ws_url"],
                    "deployment_suffix": cfg.get("deployment_suffix"),
                }
            )
            dac_service = import_module(dac_package).run(plan, dac_config)

    # Deploy sequence-sender
    ssender_config = cfg.get("ssender")
    if ssender_config:
        plan.exec(
            description="Allowing time for Sequencer DS to avoid SequenceSender failure",
            service_name="foo" + cfg["deployment_suffix"],
            recipe=ExecRecipe(command=["sleep", "20"]),
        )
        ds_url = "{}:{}".format(
            # port specified as sequencer_ds_port for both services
            rpc_service.ip_address,
            cfg["sequencer_ds_port"],
        )
        rpc_url = l2_rpc_url
        if ssender_config.get("read_from_sequencer"):
            ds_url = "{}:{}".format(
                sequencer_service.ip_address, cfg["sequencer_ds_port"]
            )
            rpc_url = l2_seq_url
        ssender_config = (
            ssender_config
            | cfg.get("addresses")
            | {
                "keystore_password": cfg["contracts"]["keystore_password"],
                "l1_rpc_url": cfg["contracts"]["l1_rpc_url"],
                "l2_rpc_url": rpc_url,
                "is_validium": contracts_config.get("validium"),
                "l1_chain_id": cfg["l1"]["chain_id"],
                "ds_url": ds_url,
                "deployment_suffix": cfg.get("deployment_suffix"),
            }
        )
        import_module(ssender_package).run(plan, ssender_config)

    aggregator_config = cfg.get("aggregator")
    if aggregator_config:
        ds_url = "{}:{}".format(
            # port specified as sequencer_ds_port for both services
            rpc_service.ip_address,
            cfg["sequencer_ds_port"],
        )
        rpc_url = l2_rpc_url
        if aggregator_config.get("read_from_sequencer"):
            ds_url = "{}:{}".format(
                sequencer_service.ip_address, cfg["sequencer_ds_port"]
            )
            rpc_url = l2_seq_url
        aggregator_config = (
            aggregator_config
            | db_configs
            | cfg.get("addresses")
            | {
                "aggregator_port": cfg["aggregator_port"],
                "ds_url": ds_url,
                "keystore_password": cfg["contracts"]["keystore_password"],
                "l1_rpc_url": cfg["contracts"]["l1_rpc_url"],
                "l2_rpc_url": rpc_url,
                "rollup_fork_id": cfg["contracts"]["rollup_fork_id"],
                "is_validium": contracts_config.get("validium"),
                "l1_chain_id": cfg["l1"]["chain_id"],
                "deployment_suffix": cfg.get("deployment_suffix"),
            }
        )
        aggregator_service = import_module(aggregator_package).run(
            plan, aggregator_config
        )

    # Deploy mockprover
    mockprover_config = cfg.get("mockprover")
    if mockprover_config:
        mockprover_config |= {
            "aggregator_port": cfg["aggregator_port"],
            "aggregator_host": aggregator_service.ip_address,
            "deployment_suffix": cfg["deployment_suffix"],
        }
        import_module(mockprover_package).run(plan, mockprover_config)

    # Deploy L2 Blockscout
    bs_config = cfg.get("blockscout", {}).get("enabled")
    if bs_config:
        bs_config = {
            "deployment_suffix": cfg["deployment_suffix"],
            "l2_chain_id": cfg["contracts"]["l2_chain_id"],
            "l2_rpc_url": l2_rpc_url,
            "l2_ws_url": "ws://{}:{}".format(
                sequencer_service.ip_address, cfg["sequencer_rpc_port"]
            ),
        }
        import_module(blockscout_package).run(plan, bs_config)
