ethereum_package = import_module(
    "github.com/ethpandaops/ethereum-package/main.star@4.2.0"
)

GETH_IMAGE = "ethereum/client-go:v1.14.8"
LIGHTHOUSE_IMAGE = "sigp/lighthouse:v5.3.0"


def run(plan, cfg):
    ethereum_package.run(
        plan,
        {
            "participants": [
                {
                    # Execution layer (EL)
                    "el_type": "geth",
                    "el_image": GETH_IMAGE,
                    # Consensus layer (CL)
                    "cl_type": "lighthouse",
                    "cl_image": LIGHTHOUSE_IMAGE,
                    "use_separate_vc": True,
                    # Validator parameters
                    "vc_type": "lighthouse",
                    "vc_image": LIGHTHOUSE_IMAGE,
                    # Participant parameters
                    "count": 1,
                }
            ],
            "network_params": {
                # The ethereum package requires the network id to be a string.
                "network_id": str(cfg["chain_id"]),
                "preregistered_validator_keys_mnemonic": cfg["preallocated_mnemonic"],
                "seconds_per_slot": cfg["seconds_per_slot"],
                "preset": cfg["preset"],
            },
            "additional_services": cfg["additional_services"],
            "port_publisher": {
                "el": {
                    "enabled": cfg.get("rpc_public_port", False),
                    # tcp-discovery uses first available port (18121)
                    # engine-rpc uses next available port (18122)
                    # finally, rpc uses third available port (18123)
                    "public_port_start": 18121,
                },
            },
        },
    )
