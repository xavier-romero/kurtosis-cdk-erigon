DAC_CONFIG_FILE = "dac-config.toml"

def run(plan, cfg):
    # _gen_config_file(plan, cfg)

    service_name = cfg["service_name"] + cfg["deployment_suffix"]
    service_image = cfg["image"]
    service_files = {
        "/config": Directory(
            artifact_names=[
                plan.get_files_artifact("dac.keystore"),
                plan.get_files_artifact(DAC_CONFIG_FILE),
            ]
        )
    }
    service_entrypoint = ["/app/cdk-data-availability"]
    service_cmd = ["run", "--cfg", "/config/" + DAC_CONFIG_FILE]
    service_ports = {"dac": PortSpec(cfg["dac_port"], application_protocol="tcp")}

    service_config = ServiceConfig(
        image=service_image,
        files=service_files,
        entrypoint=service_entrypoint,
        cmd=service_cmd,
        ports=service_ports,
    )

    service = plan.add_service(
        name=service_name,
        config=service_config,
        description="Adding service {}".format(service_name),
    )

    return service
