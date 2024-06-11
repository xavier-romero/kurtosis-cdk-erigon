def run(plan, cfg):
    service_name = "index"
    service_image = cfg["image"]
    # service_files = {
    #     "/config": Directory(
    #         artifact_names=[
    #             plan.get_files_artifact("aggregator.keystore"),
    #             plan.get_files_artifact(AGGREGATOR_CONFIG_FILE),
    #             plan.get_files_artifact("genesis.json"),
    #         ]
    #     )
    # }
    # service_cmd = [
    #     "/bin/sh",
    #     "-c",
    #     "/app/zkevm-aggregator run --network custom --custom-network-file /config/genesis.json --cfg /config/"
    #     + AGGREGATOR_CONFIG_FILE,
    # ]
    service_ports = {
        service_name: PortSpec(cfg["public_port"], application_protocol="http")
    }

    service_config = ServiceConfig(
        image=service_image,
        # files=service_files,
        # cmd=service_cmd,
        ports=service_ports,
    )

    service = plan.add_service(
        name=service_name,
        config=service_config,
        description="Adding service {}".format(service_name),
    )

    return service
