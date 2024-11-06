BRIDGE_CONFIG_FILE = "bridge-config.toml"


def run(plan, cfg):
    service_name = cfg["service_name"] + cfg["deployment_suffix"]
    service_image = cfg["image"]
    is_bridge_public_port = cfg.get("bridge_public_port", False)

    service_files = {
        "/config": Directory(
            artifact_names=[
                plan.get_files_artifact("claimtxmanager.keystore"),
                plan.get_files_artifact(BRIDGE_CONFIG_FILE),
            ]
        )
    }
    service_cmd = ["/app/zkevm-bridge", "run", "--cfg", "/config/" + BRIDGE_CONFIG_FILE]
    service_ports = {"bridge": PortSpec(cfg["bridge_port"], application_protocol="tcp")}
    public_ports = service_ports if is_bridge_public_port else {}

    service_config = ServiceConfig(
        image=service_image,
        files=service_files,
        cmd=service_cmd,
        ports=service_ports,
        public_ports=public_ports,
    )

    service = plan.add_service(
        name=service_name,
        config=service_config,
        description="Adding service {}".format(service_name),
    )

    return service
