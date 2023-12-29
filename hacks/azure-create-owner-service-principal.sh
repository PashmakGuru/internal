#!/bin/bash
#
# Create AzureRM Credentials for Terraform Cloud
# This script automates the setup of a service principal in Azure, which is used by Terraform Cloud.
# It checks for necessary prerequisites (Azure CLI, jq), creates a service principal, assigns it a role,
# and outputs the credentials. These credentials are to be added to Terraform Cloud's variable set for
# managing Azure resources.

set -euo pipefail

sp_name="terraform-cloud"
sp_role="Owner"

check_prequestics() {
    if ! command -v az > /dev/null; then
        echo "📛 Azure CLI is not installed."
        exit 1
    fi

    if ! command -v jq > /dev/null; then
        echo "📛 jq utility is not installed."
        exit 1
    fi
}

create_and_report() {
    if ! output=$(az account list | jq ".[].id|select(.==\"$subscription\")"); then
        echo "📛 Azure subscription access is not found in your client. Use the following command to login with access to it."
        echo "az login"
        exit 1
    fi

    az account set --subscription $subscription

    search_sp=$(az ad sp list --display-name $sp_name | jq -e ".[].displayName | select(\"$sp_name\")")
    if [ "$search_sp" ]; then
        echo "⚠️  Service principle \"$sp_name\" already exists. Do you want to renew it? The previous secret (password) will be lost too."
        read -p "Type \"renew [name-of-the-sp]\" to confirm or anything else to abort: " confirm

        if [ "$confirm" != "renew $sp_name" ]; then
            echo "Aborted."
            exit 0
        fi
    fi

    creds=$(az ad sp create-for-rbac --name $sp_name --role $sp_role --scopes "/subscriptions/$subscription" --only-show-errors -o json)

    az ad app permission grant \
        --id "$(echo $creds | jq -r -e '.appId')" \
        --api "00000003-0000-0000-c000-000000000000" \
        --scope "Directory.ReadWrite.All" \
        --consent-type "AllPrincipals" > /dev/null

    cat << INFO

✨ Add the following environments to the Terraform Cloud's 'remote-operations' workspace variable-set.

azure_subscription_id: $subscription
azure_client_id:       $(echo $creds | jq -r -e '.appId')
azure_client_secret:   $(echo $creds | jq -r -e '.password')
azure_tenant_id:       $(echo $creds | jq -r -e '.tenant')

⚠️  Confidental content. Don't share or keep in logs.
⚠️  You won't see the azure_client_secret again.
INFO
}

main() {
    check_prequestics
    read -p "Azure Subscription ID: " subscription
    create_and_report
}

main
