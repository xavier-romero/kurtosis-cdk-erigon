EXECUTOR_CONFIG_FILE = "executor-config.json"

def run(plan, cfg):
    service_name = cfg["service_name"] + cfg["deployment_suffix"]
    service_image = cfg["image"]
    service_files = {
        "/config": Directory(
            artifact_names=[plan.get_files_artifact(EXECUTOR_CONFIG_FILE)]
        )
    }
    service_port = cfg["executor_port"]
    port_name = cfg["service_name"]

    cpu_arch_result = plan.run_sh(
        description="Determining CPU system architecture",
        run="uname -m | tr -d '\n'",
    )
    cpu_arch = cpu_arch_result.output
    service_cmd = [
        '[[ "{0}" == "aarch64" || "{0}" == "arm64" ]] && export EXPERIMENTAL_DOCKER_DESKTOP_FORCE_QEMU=1; zkProver -c /config/{1}'.format(
            cpu_arch, EXECUTOR_CONFIG_FILE
        ),
    ]

    service_config = ServiceConfig(
        image=service_image,
        ports={
            "{}{}".format(port_name, service_port): PortSpec(
                service_port, application_protocol="http", wait="60s"
            )
        },
        files=service_files,
        entrypoint=["/bin/bash", "-c"],
        cmd=service_cmd,
    )

    service = plan.add_service(
        name=service_name,
        config=service_config,
        description="Adding service {}".format(service_name),
    )

    return service
