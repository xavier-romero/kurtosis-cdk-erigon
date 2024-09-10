MOCKPROVER_CONFIG_TEMPLATE = "./config/mockprover-config.json"
MOCKPROVER_CONFIG_FILE = "mockprover-config.json"


def _gen_config_file(plan, cfg):
    cfg_file_tpl = read_file(src=MOCKPROVER_CONFIG_TEMPLATE)

    plan.render_templates(
        name=MOCKPROVER_CONFIG_FILE,
        config={MOCKPROVER_CONFIG_FILE: struct(template=cfg_file_tpl, data=cfg)},
    )


def run(plan, cfg):
    _gen_config_file(plan, cfg)

    service_name = cfg["service_name"] + cfg["deployment_suffix"]
    service_image = cfg["image"]
    service_files = {
        "/config": Directory(
            artifact_names=[plan.get_files_artifact(MOCKPROVER_CONFIG_FILE)]
        )
    }

    cpu_arch_result = plan.run_sh(
        description="Determining CPU system architecture",
        run="uname -m | tr -d '\n'",
    )
    cpu_arch = cpu_arch_result.output

    service_cmd = [
        '[[ "{0}" == "aarch64" || "{0}" == "arm64" ]] && export EXPERIMENTAL_DOCKER_DESKTOP_FORCE_QEMU=1; '.format(cpu_arch),
        "zkProver",
        "-c",
        "/config/" + MOCKPROVER_CONFIG_FILE,
    ]

    service_config = ServiceConfig(
        image=service_image,
        files=service_files,
        cmd=service_cmd,
    )

    service = plan.add_service(
        name=service_name,
        config=service_config,
        description="Adding service {}".format(service_name),
    )

    return service
