### CDK-ERIGON VIA KURTOSIS


## What is it ? 

Provision zkEVM L2 networks (now powered by erigon) in <15min with a 1-line cmd !
Under the hood, we use an open-source docker and k8s abstraction called [Kurtosis](https://docs.kurtosis.com/install/)

## How to Run ? (exact steps)

install kurtosis (mac), must install specific version:
```bash
brew install kurtosis-tech/tap/kurtosis-cli
```

** user must have docker-daemon running for next cmds to succeed **

deploy cdk-erigon devnet:
```bash
kurtosis run --enclave erigon02 --image-download always .
```

destroy cdk-erigon devnet:
```bash
kurtosis clean --all
```

## Troubleshooting

if you experience an error like the following (*errors on el-lighthouse service*):
```bash
== FINISHED SERVICE 'el-1-geth-lighthouse' LOGS ===================================
Caused by: An error occurred while waiting for all TCP and UDP ports to be open
Caused by: Unsuccessful ports check for IP '172.16.0.12' and port spec '{privatePortSpec:0xc0006f7020}', even after '240' retries with '500' milliseconds in between retries. Timeout '2m0s' has been reached
Caused by: An error occurred while calling network address '172.16.0.12:8551' with port protocol 'TCP' and using time out '200ms'
Caused by: dial tcp 172.16.0.12:8551: i/o timeout

Error encountered running Starlark code.
```

..this is usually a kurtosis-cli version related issue. You can install a specific
version of kurtosis as exampled below:
```bash
echo "deb [trusted=yes] https://apt.fury.io/kurtosis-tech/ /" | sudo tee /etc/apt/sources.list.d/kurtosis.list
sudo apt update
sudo apt install kurtosis-cli=0.89.3
kurtosis analytics disable
```


inspect all services:
```bash
kurtosis enclave inspect erigon
```


reviewing kurtosis service logs:
```bash
kurtosis service logs erigon erigon-sequencer
```
