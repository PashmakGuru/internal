#!/bin/bash
#
# Azure Register Subscription Providers
#
# This bash script automates the registration of crucial Azure service providers
# like Compute, KeyVault, ContainerService, and CDN for a selected subscription.
# It checks Azure CLI installation, lists subscriptions, and ensures provider
# readiness, simplifying Azure environment configurations.

set -euo pipefail

provider=(
    "Microsoft.Compute"
    "Microsoft.KeyVault"
    "Microsoft.ContainerService"
    "Microsoft.Cdn"
)

check_prequestics() {
    if ! command -v az > /dev/null; then
        echo "📛 Azure CLI is not installed."
        exit 1
    fi
}

list_subscriptions() {
    echo "Your authenticated subscriptions:"
    az account list | jq -r "map({id, name}) | .[] | [.id, .name] | @tsv" | column -ts $'\t'
}

create_and_report() {
    if ! output=$(az account list | jq ".[].id|select(.==\"$subscription\")"); then
        echo "📛 Azure subscription access is not found in your client. Use the following command to login with access to it."
        echo "az login"
        exit 1
    fi

    az account set --subscription $subscription

    echo "Retgistered Providers:"
    az provider list --query "[?registrationState=='Registered']" --output table

    echo ""
    for provider in "${provider[@]}"; do
        printf "Registering $provider..."
        az provider register --wait --namespace "$provider"
        printf " ✅\n"
    done
}

main() {
    check_prequestics
    list_subscriptions
    echo ""
    read -p "Azure Subscription ID: " subscription
    create_and_report
}

main
