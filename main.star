config = "./config.star"
ethereum = "./ethereum.star"
contracts = "./contracts.star"
erigon = "./erigon.star"


def run(plan, args):
    foo = plan.add_service(
        name="foo",
        config=ServiceConfig(image="alpine:latest", cmd=["sleep", "infinity"]),
        description="Adding foo service",
    )

    cfg = import_module(config).get_config(args)

    # L1 deployment
    l1_config = cfg.get("l1", {})
    if l1_config:
        import_module(ethereum).run(plan, l1_config)
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
        plan.print("Deploying zkevm contracts on L1")
        import_module(contracts).run(plan, cfg | contracts_config | addresses)
    else:
        plan.print("Skipping the deployment of zkevm contracts on L1")

    # Deploy Erigon
    erigon_config = cfg.get("erigon") | cfg.get("addresses")
    if erigon_config:
        # plan.exec(
        #     description="Sleeping for a while",
        #     service_name="foo",
        #     recipe=ExecRecipe(command=["sleep", "300"]),
        # )
        sequencer_service, rpc_service = import_module(erigon).run(plan, erigon_config)
    else:
        plan.print("Skipping the deployment of Erigon")

    # Deploy sequence-sender
    ssender_config = cfg.get("ssender")
    if ssender_config:
        ssender_config = (
            ssender_config
            | cfg.get("addresses")
            | {
                "keystore_password": cfg["contracts"]["keystore_password"],
                "l1_rpc_url": cfg["contracts"]["l1_rpc_url"],
                "l1_chain_id": cfg["l1"]["chain_id"],
                "datastream_address": "{}:6900".format(sequencer_service.ip_address),
            }
        )
        import_module("./ssender.star").run(plan, ssender_config)
