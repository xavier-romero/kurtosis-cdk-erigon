def _deploy_service(plan, cfg, service):
    service_ports = cfg[service]["PORTS"]
    public_ports = cfg[service].get("PUBLIC_PORTS", [])
    service_name = cfg[service]["NAME"] + cfg["deployment_suffix"]
    port_name = cfg[service]["NAME"]
    service_image = cfg[service]["IMAGE"]
    service_cmd = cfg[service]["CMD"]
    service_vars = cfg[service]["ENV_VARS"]

    cfg_path = cfg["COMMON"]["CONFIG_PATH"]
    datadir_path = cfg["COMMON"]["DATADIR_PATH"]

    service_config = ServiceConfig(
        image=service_image,
        ports={
            "{}{}".format(port_name, service_port): PortSpec(
                service_port, application_protocol="http", wait="20s"
            )
            for service_port in service_ports
        },
        public_ports={
            "{}{}".format(port_name, service_port): PortSpec(
                service_port, application_protocol="http", wait="20s"
            )
            for service_port in public_ports
        },
        env_vars=service_vars,
        files={
            cfg_path: Directory(
                artifact_names=[
                    plan.get_files_artifact("erigon-" + service.lower() + ".yaml"),
                    plan.get_files_artifact("dynamic-kurtosis-allocs.json"),
                    plan.get_files_artifact("dynamic-kurtosis-conf.json"),
                    plan.get_files_artifact("dynamic-kurtosis-chainspec.json"),
                ]
            ),
            datadir_path: Directory(
                persistent_key="erigon-{}-datadir".format(service_name.lower())
            ),
        },
        cmd=service_cmd,
        # Temporary solution to avoid permission issues on datadir
        # Erigon by defaults uses user 1000:1000 so we would need to set the folder perms
        user=User(uid=0, gid=0),
    )

    service = plan.add_service(
        name=service_name,
        config=service_config,
        description="Adding service {}".format(service_name),
    )

    return service


def run(plan, cfg):
    plan.print("Deploying Erigon Sequencer")
    sequencer_service = _deploy_service(plan, cfg, "SEQUENCER")

    plan.print("Deploying Erigon RPC")
    rpc_service = _deploy_service(plan, cfg, "RPC")

    return sequencer_service, rpc_service
