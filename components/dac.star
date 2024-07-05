DAC_CONFIG_TEMPLATE = "./config/dac-config.toml"
DAC_CONFIG_FILE = "dac-config.toml"


def _gen_config_file(plan, cfg):
    cfg_file_tpl = read_file(src=DAC_CONFIG_TEMPLATE)

    result1 = plan.run_sh(
        run="jq -j .polygonDataCommitteeAddress /input/create_rollup_output.json",
        files={"/input": plan.get_files_artifact("create_rollup_output.json")},
    )
    result2 = plan.run_sh(
        run="jq -j .rollupAddress /input/create_rollup_output.json",
        files={"/input": plan.get_files_artifact("create_rollup_output.json")},
    )
    extra_cfg = {
        "polygonDataCommitteeAddress": result1.output.strip(),
        "zkEVMAddress": result2.output.strip(),
    }

    plan.render_templates(
        name=DAC_CONFIG_FILE,
        config={DAC_CONFIG_FILE: struct(template=cfg_file_tpl, data=cfg | extra_cfg)},
    )


def run(plan, cfg):
    _gen_config_file(plan, cfg)

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
