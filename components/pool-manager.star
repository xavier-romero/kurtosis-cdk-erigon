PM_CONFIG_FILE = "pool-manager-config.toml"


def run(plan, cfg):
    service_name = cfg["service_name"] + cfg["deployment_suffix"]
    service_image = cfg["image"]
    service_files = {
        "/config": Directory(
            artifact_names=[
                plan.get_files_artifact(PM_CONFIG_FILE),
            ]
        )
    }
    service_cmd = [
        "/app/zkevm-pool-manager",
        "run",
        "--cfg",
        "/config/" + PM_CONFIG_FILE,
    ]
    service_ports = {"dac": PortSpec(cfg["pm_port"], application_protocol="tcp")}

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
