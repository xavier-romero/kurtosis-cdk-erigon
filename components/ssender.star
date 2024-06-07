SSENDER_CONFIG_TEMPLATE = "./config/ssender-config.toml"
SSENDER_CONFIG_FILE = "ssender-config.toml"


def _gen_config_file(plan, cfg):
    cfg_file_tpl = read_file(src=SSENDER_CONFIG_TEMPLATE)

    plan.render_templates(
        name=SSENDER_CONFIG_FILE,
        config={SSENDER_CONFIG_FILE: struct(template=cfg_file_tpl, data=cfg)},
    )


def run(plan, cfg):
    _gen_config_file(plan, cfg)

    service_name = "ssender"
    service_image = cfg["image"]
    service_files = {
        "/config": Directory(
            artifact_names=[
                plan.get_files_artifact("sequencer.keystore"),
                plan.get_files_artifact(SSENDER_CONFIG_FILE),
                plan.get_files_artifact("genesis.json"),
            ]
        ),
        "/data": Directory(persistent_key="ssender-data"),
    }
    service_cmd = [
        "/bin/sh",
        "-c",
        "/app/zkevm-seqsender run --network custom --custom-network-file /config/genesis.json --cfg /config/"
        + SSENDER_CONFIG_FILE
        # + " --components sequence-sender",
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
