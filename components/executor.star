EXECUTOR_CONFIG_TEMPLATE = "./config/executor-config.json"
EXECUTOR_CONFIG_FILE = "executor-config.json"


def _gen_config_file(plan, cfg):
    cfg_file_tpl = read_file(src=EXECUTOR_CONFIG_TEMPLATE)

    plan.render_templates(
        name=EXECUTOR_CONFIG_FILE,
        config={EXECUTOR_CONFIG_FILE: struct(template=cfg_file_tpl, data=cfg)},
    )


def run(plan, cfg):
    _gen_config_file(plan, cfg)

    service_name = cfg["service_name"] + cfg["deployment_suffix"]
    service_image = cfg["image"]
    service_files = {
        "/config": Directory(
            artifact_names=[plan.get_files_artifact(EXECUTOR_CONFIG_FILE)]
        )
    }
    service_port = cfg["executor_port"]
    port_name = cfg["service_name"]
    service_cmd = [
        "zkProver",
        "-c",
        "/config/" + EXECUTOR_CONFIG_FILE,
    ]

    service_config = ServiceConfig(
        image=service_image,
        ports={
            "{}{}".format(port_name, service_port): PortSpec(
                service_port, application_protocol="http", wait="20s"
            )
        },
        files=service_files,
        cmd=service_cmd,
    )

    service = plan.add_service(
        name=service_name,
        config=service_config,
        description="Adding service {}".format(service_name),
    )

    return service
