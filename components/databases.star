POSTGRES_IMAGE = "postgres:16.2"
POSTGRES_SERVICE_NAME = "postgres"
POSTGRES_PORT = 5432
POSTGRES_MASTER_DB = "master"
POSTGRES_MASTER_USER = "master_user"
POSTGRES_MASTER_PASSWORD = "master_password"
MASTER_INIT_SQL = "./config/init.sql"

DATABASES = {
    "aggr_db": {
        "name": "ggr_db",
        "user": "aggr_user",
        "password": "rJXJN6iUAczh4oz8HRKYbVM8yC7tPeZm",
        # "init": read_file(src="./templates/databases/event-db-init.sql"),
    },
    "aggrsync_db": {
        "name": "aggrsync_db",
        "user": "aggrsync_user",
        "password": "Qso5wMcLAN3oF7EfaawzgWKUUKWM3Vov",
    },
    "dac_db": {
        "name": "dac_db",
        "user": "dac_user",
        "password": "aiqbvbN1x6BhiUvsJfljC0AmLeKGac25",
    },
    "pm_db": {
        "name": "pm_db",
        "user": "pm_user",
        "password": "fGfsPQnZC5WwGHnOJE1eQ0iYr9TvKOND",
    },
    "bridge_db": {
        "name": "bridge_db",
        "user": "bridge_user",
        "password": "SqucbLEU14Lg8fUDPfSs3tBiw78uu7rF",
    },
}


def _service_name(suffix):
    return POSTGRES_SERVICE_NAME + suffix


def get_db_configs(suffix):
    return {
        k: v | {"hostname": _service_name(suffix), "port": POSTGRES_PORT}
        for k, v in DATABASES.items()
    }


def create_postgres_service(plan, db_configs, suffix):
    init_script_tpl = read_file(src=MASTER_INIT_SQL)
    init_script = plan.render_templates(
        name="init.sql" + suffix,
        config={
            "init.sql": struct(
                template=init_script_tpl,
                data={
                    "dbs": db_configs,
                    "master_db": POSTGRES_MASTER_DB,
                    "master_user": POSTGRES_MASTER_USER,
                },
            )
        },
    )

    postgres_service_cfg = ServiceConfig(
        image=POSTGRES_IMAGE,
        ports={
            "postgres": PortSpec(POSTGRES_PORT, application_protocol="postgresql"),
        },
        env_vars={
            "POSTGRES_DB": POSTGRES_MASTER_DB,
            "POSTGRES_USER": POSTGRES_MASTER_USER,
            "POSTGRES_PASSWORD": POSTGRES_MASTER_PASSWORD,
        },
        files={"/docker-entrypoint-initdb.d/": init_script},
        cmd=["-N 1000"],
    )

    plan.add_service(
        name=_service_name(suffix),
        config=postgres_service_cfg,
        description="Starting Postgres Service",
    )


def run(plan, suffix):
    db_configs = DATABASES.values()
    create_postgres_service(plan, db_configs, suffix)
