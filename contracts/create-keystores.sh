#!/bin/bash
# This script creates keystores for all the different zkevm/cdk node components.
set -e

# Create a go-ethereum style encrypted keystore.
create_geth_keystore() {
    local keystore_name="$1"
    local private_key="$2"
    local password="$3"

    echo "Creating keystore for $keystore_name, private_key:$private_key, password:$password"

    temp_dir="/tmp/$keystore_name"
    output_dir="/opt/zkevm"
    mkdir -p "$temp_dir"
    polycli parseethwallet --hexkey "$private_key" --password "$password" --keystore "$temp_dir"
    mv "$temp_dir"/UTC* "$output_dir/$keystore_name"
    jq < "$output_dir/$keystore_name" > "$output_dir/$keystore_name.new"
    mv "$output_dir/$keystore_name.new" "$output_dir/$keystore_name"
    chmod a+r "$output_dir/$keystore_name"
    rm -rf "$temp_dir"
}

create_geth_keystore "sequencer.keystore"       "{{.sequencer.private_key}}"       "{{.keystore_password}}"
create_geth_keystore "aggregator.keystore"      "{{.aggregator.private_key}}"      "{{.keystore_password}}"
create_geth_keystore "claimtxmanager.keystore"  "{{.claimtxmanager.private_key}}"  "{{.keystore_password}}"
create_geth_keystore "agglayer.keystore"        "{{.agglayer.private_key}}"        "{{.keystore_password}}"
create_geth_keystore "dac.keystore"             "{{.dac.private_key}}"             "{{.keystore_password}}"
create_geth_keystore "proofsigner.keystore"     "{{.proofsigner.private_key}}"     "{{.keystore_password}}"
