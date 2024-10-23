CDKNODE_CONFIG_FILE = "cdknode-config.toml"
CDKNODE_GENESIS_FILE = "node-genesis.json"


def run(plan, cfg):
    service_name = cfg["service_name"] + cfg["deployment_suffix"]
    service_image = cfg["image"]
    service_files = {
        "/config": Directory(
            artifact_names=[
                plan.get_files_artifact("aggregator.keystore"),
                plan.get_files_artifact("sequencer.keystore"),
                plan.get_files_artifact(CDKNODE_CONFIG_FILE),
                plan.get_files_artifact(CDKNODE_GENESIS_FILE),
            ]
        ),
        "/app/data": Directory(persistent_key="{}-data".format(service_name.lower())),
    }
    service_cmd = [
        "/bin/sh",
        "-c",
        "cdk-node run -custom-network-file=/config/"
        + CDKNODE_GENESIS_FILE
        + " -cfg=/config/"
        + CDKNODE_CONFIG_FILE
        + " -components=aggregator,sequence-sender",
    ]
    service_ports = {
        "aggregator": PortSpec(cfg["aggregator_port"], application_protocol="grpc")
    }

    service_config = ServiceConfig(
        image=service_image,
        files=service_files,
        cmd=service_cmd,
        ports=service_ports,
    )

    service = plan.add_service(
        name=service_name,
        config=service_config,
        description="Adding service {}".format(service_name),
    )

    return service
