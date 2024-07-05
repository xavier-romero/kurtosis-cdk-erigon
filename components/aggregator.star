AGGREGATOR_CONFIG_TEMPLATE = "./config/aggregator-config.toml"
AGGREGATOR_CONFIG_FILE = "aggregator-config.toml"


def _gen_config_file(plan, cfg):
    cfg_file_tpl = read_file(src=AGGREGATOR_CONFIG_TEMPLATE)

    result = plan.run_sh(
        run="jq -j '.genesis[] | select(.contractName == \"PolygonZkEVMGlobalExitRootL2 proxy\") | .address' /input/genesis.json",
        files={"/input": plan.get_files_artifact("genesis.json")},
    )
    extra_cfg = {"ger_l2_address": result.output.strip()}

    plan.render_templates(
        name=AGGREGATOR_CONFIG_FILE,
        config={
            AGGREGATOR_CONFIG_FILE: struct(template=cfg_file_tpl, data=cfg | extra_cfg)
        },
    )


def run(plan, cfg):
    _gen_config_file(plan, cfg)

    service_name = cfg["service_name"] + cfg["deployment_suffix"]
    service_image = cfg["image"]
    service_files = {
        "/config": Directory(
            artifact_names=[
                plan.get_files_artifact("aggregator.keystore"),
                plan.get_files_artifact(AGGREGATOR_CONFIG_FILE),
                plan.get_files_artifact("genesis.json"),
            ]
        )
    }
    service_cmd = [
        "/bin/sh",
        "-c",
        "/app/zkevm-aggregator run --network custom --custom-network-file /config/genesis.json --cfg /config/"
        + AGGREGATOR_CONFIG_FILE,
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
