# SSENDER_CONFIG_TEMPLATE = "./config/ssender-config.toml"
SSENDER_CONFIG_FILE = "ssender-config.toml"
SSENDER_GENESIS_FILE = "node-genesis.json"

# def _gen_config_file(plan, cfg):
#     cfg_file_tpl = read_file(src=SSENDER_CONFIG_TEMPLATE)

#     plan.render_templates(
#         name=SSENDER_CONFIG_FILE,
#         config={SSENDER_CONFIG_FILE: struct(template=cfg_file_tpl, data=cfg)},
#     )


def run(plan, cfg):
    # _gen_config_file(plan, cfg)

    service_name = cfg["service_name"] + cfg["deployment_suffix"]
    service_image = cfg["image"]
    service_files = {
        "/config": Directory(
            artifact_names=[
                plan.get_files_artifact("sequencer.keystore"),
                plan.get_files_artifact(SSENDER_CONFIG_FILE),
                plan.get_files_artifact(SSENDER_GENESIS_FILE),
            ]
        ),
        "/data": Directory(persistent_key="ssender-data"),
    }
    service_cmd = [
        "/bin/sh",
        "-c",
        "/app/zkevm-seqsender run --network custom --custom-network-file /config/"
        + SSENDER_GENESIS_FILE
        + " --cfg /config/"
        + SSENDER_CONFIG_FILE,
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
