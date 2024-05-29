config = "./config.star"
ethereum = "./ethereum.star"
contracts = "./contracts.star"
erigon = "./erigon.star"
blockscout = "./blockscout.star"


def run(plan, args):
    foo = plan.add_service(
        name="foo",
        config=ServiceConfig(image="alpine:latest", cmd=["sleep", "infinity"]),
        description="Adding foo service"
    )

    cfg = import_module(config).get_config(args)

    # L1 deployment
    l1_config = cfg.get("l1", {})
    if l1_config:
        import_module(ethereum).run(plan, l1_config)
        if l1_config.get("blockscout"):
            import_module(blockscout).run(plan)
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
        import_module(erigon).run(plan, erigon_config)
    else:
        plan.print("Skipping the deployment of Erigon")
