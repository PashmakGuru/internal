#!/bin/bash
#
# Bootstrap Terraform Cloud
# Create an organization, project, and workflow that's designed to
# enable our other TFC codes to apply, i.e. it makes us able to
# manage the real organization and projcet via tfc_* modules.

set -euo pipefail

required_envs=("TF_API_TOKEN" "TF_CLOUD_ORGANIZATION" "TF_CLOUD_EMAIL", "TF_PROJECT", "TF_WORKSPACE")

check_required_envs() {
    for var in "${env_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo "Error: Environment variable $var is not set."
            exit 1
        fi
    done
}

call() {
    curl -sS \
        --header "Authorization: Bearer $TF_API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" $@
}

get_project_id () {
    PROJECTS=$(call https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/projects)
    echo $PROJECTS | jq -r ".data[] | select(.attributes.name == \"$TF_PROJECT\").id"
}


ensure_org_exists() {
    if call -f -o /dev/null --head https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/workspaces; then
        echo "🏢 Organization exists."
    else
        echo "🏢 Organization does not exist. Creating..."
        call -f -o /dev/null -X POST \
            https://app.terraform.io/api/v2/organizations \
            --data @- << REQUEST_BODY
    {
        "data": {
            "type": "organizations",
            "attributes": {
                "name": "$TF_CLOUD_ORGANIZATION",
                "email": "$TF_CLOUD_EMAIL"
            }
        }
    }
REQUEST_BODY
    fi
}

ensure_project_exists() {
    if [ -z "$(get_project_id)" ]; then
        echo "💼 Project does not exist. Creating..."
        call -f -o /dev/null -X POST \
            https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/projects \
            --data @- << REQUEST_BODY
    {
        "data": {
            "attributes": {
                "name": "$TF_PROJECT"
            },
            "type": "projects"
        }
    }
REQUEST_BODY
    else
        echo "💼 Project exists."
    fi
}


ensure_workspace_exists() {
    if call -f -o /dev/null --head https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/workspaces/$TF_WORKSPACE; then
        echo "📋 Workspace exists."
    else
        echo "📋 Workspace does not exist. Creating..."
        PROJECT_ID=$(get_project_id)
        call -f -o /dev/null -X POST https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/workspaces \
            --data @- << REQUEST_BODY
    {
        "data": {
            "attributes": {
                "name": "$TF_WORKSPACE",
                "execution-mode": "remote",
                "description": "This workspace is bootstrapped via GH workflow (bootstrap-terraform-cloud.yaml). It enables us to perform remote operations on TFC and synchronize its resources."
            },
            "relationships": {
                "project": {
                    "data": {
                        "type": "projects",
                        "id": "$PROJECT_ID"
                    }
                }
            },
            "type": "workspaces"
        }
    }
REQUEST_BODY
    fi
}

main() {
    check_required_envs
    ensure_org_exists
    ensure_project_exists
    ensure_workspace_exists
    echo "All done."
}
