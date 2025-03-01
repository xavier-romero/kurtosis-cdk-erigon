config_package = "./config.star"
contracts_package = "./contracts.star"
ethereum_package = "./external/ethereum.star"
executor_package = "./components/executor.star"
erigon_package = "./components/erigon.star"
databases_package = "./components/databases.star"
# aggregator_package = "./components/aggregator.star"
# ssender_package = "./components/ssender.star"
cdknode_package = "./components/cdknode.star"
mockprover_package = "./components/mockprover.star"
dac_package = "./components/dac.star"
poolmanager_package = "./components/pool-manager.star"
bridge_package = "./components/bridge.star"
blockscout_package = "./external/blockscout.star"


def run(plan, args):
    # Import config
    cfg = import_module(config_package).get_config(args)

    # Deploy database (aggregator)
    databases = import_module(databases_package)
    databases.run(plan, suffix=cfg["deployment_suffix"])
    db_configs = databases.get_db_configs(cfg["deployment_suffix"])

    # L1 deployment
    l1_config = cfg.get("l1", {})
    if l1_config.get("deploy", True):
        import_module(ethereum_package).run(plan, l1_config)
    else:
        plan.print("Skipping the deployment of a local L1")

    contracts_config = cfg.get("contracts")
    # Deploy zkevm contracts on L1.
    if contracts_config.get("deploy", True):
        addresses = cfg.get("addresses")
        if not addresses:
            fail("Missing addresses for zkevm contracts")
        contracts_config = contracts_config | {
            "l1_funded_mnemonic": cfg.get("l1").get("preallocated_mnemonic"),
            "l1_funding_amount": cfg.get("l1_funding_amount"),
            "addresses": addresses,
            "dac_urls": "http://{}:{}".format(
                cfg["dac"]["service_name"] + cfg["deployment_suffix"],
                cfg["dac"]["dac_port"],
            ),
            "gasless": cfg.get("erigon", {}).get("gasless"),
            "extra": {
                "executor_port": cfg["zkProver"]["executor"]["executor_port"],
                "sequencer_rpc": "http://{}:{}".format(
                    cfg["erigon"]["SEQUENCER"]["NAME"] + cfg["deployment_suffix"],
                    cfg["sequencer_rpc_port"],
                ),
                "sequencer_ds": "{}:{}".format(
                    cfg["erigon"]["SEQUENCER"]["NAME"] + cfg["deployment_suffix"],
                    cfg["sequencer_ds_port"],
                ),
                "rpc_rpc": "http://{}:{}".format(
                    cfg["erigon"]["RPC"]["NAME"] + cfg["deployment_suffix"],
                    cfg["sequencer_rpc_port"],
                ),
                "rpc_ds": "{}:{}".format(
                    cfg["erigon"]["RPC"]["NAME"] + cfg["deployment_suffix"],
                    cfg["sequencer_ds_port"],
                ),
                "pm_url": "http://{}:{}".format(
                    cfg["poolmanager"]["service_name"] + cfg["deployment_suffix"],
                    cfg["poolmanager"]["pm_port"],
                ),
                "stateless_executor": cfg["zkProver"]["executor"]["service_name"]
                + cfg["deployment_suffix"],
                "sequencer_rpc_port": cfg["sequencer_rpc_port"],
                "sequencer_ds_port": cfg["sequencer_ds_port"],
                "aggregator_port": cfg["cdknode"]["aggregator_port"],
                "aggregator_host": cfg["cdknode"]["service_name"]
                + cfg["deployment_suffix"],
                "dac_port": cfg["dac"]["dac_port"],
                "l1_ws_url": contracts_config.get("l1_ws_url"),
                "pm_port": cfg["poolmanager"]["pm_port"],
                "bridge_port": cfg["bridge"]["bridge_port"],
            }
            | db_configs,
        }
        plan.print("Deploying zkevm contracts on L1")
        contracts_service = import_module(contracts_package).run(plan, contracts_config)
    else:
        plan.print("Skipping the deployment of zkevm contracts on L1")

    # Deploy DAC if enabled
    if contracts_config.get("validium"):
        dac_service = import_module(dac_package).run(plan, cfg.get("dac"))

    # Deploy executor
    import_module(executor_package).run(plan, cfg.get("zkProver"))

    # Deploy Erigon
    import_module(erigon_package).run(plan, cfg.get("erigon"))

    # Deploy Pool Manager
    import_module(poolmanager_package).run(plan, cfg.get("poolmanager"))

    if contracts_config.get("deploy", True):
        # Allow some time for DS to start
        plan.exec(
            description="Allowing time for Sequencer DS to avoid SequenceSender failure",
            service_name=contracts_service.name,
            recipe=ExecRecipe(command=["sleep", "10"]),
        )

    # Deploy sequence-sender
    # import_module(ssender_package).run(plan, cfg.get("ssender"))
    # Deploy Aggregator
    # import_module(aggregator_package).run(plan, cfg.get("aggregator"))

    # Deploy sequence-sender
    import_module(cdknode_package).run(plan, cfg.get("cdknode"))

    # Deploy mockprover
    if not contracts_config.get("real_verifier"):
        import_module(mockprover_package).run(plan, cfg.get("zkProver"))

    # Deploy Bridge
    import_module(bridge_package).run(plan, cfg.get("bridge"))

    # # Deploy L2 Blockscout
    # bs_config = cfg.get("blockscout", {}).get("enabled")
    # if bs_config:
    #     bs_config = {
    #         "deployment_suffix": cfg["deployment_suffix"],
    #         "l2_chain_id": cfg["contracts"]["l2_chain_id"],
    #         "l2_rpc_url": l2_rpc_url,
    #         "l2_ws_url": "ws://{}:{}".format(
    #             sequencer_service.ip_address, cfg["sequencer_rpc_port"]
    #         ),
    #     }
    #     import_module(blockscout_package).run(plan, bs_config)
