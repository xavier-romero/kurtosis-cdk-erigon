ethereum_package = import_module(
    "github.com/kurtosis-tech/ethereum-package/main.star@3.0.0"
)

GETH_IMAGE = "ethereum/client-go:v1.14.0"
LIGHTHOUSE_IMAGE = "sigp/lighthouse:v5.1.3"


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
            },
            "additional_services": cfg["additional_services"],
        },
    )
