#!/bin/bash
#
# Bootstrap Terraform Cloud
# Create an organization, project, and workflow that's designed to
# enable our other TFC codes to apply, i.e. it makes us able to
# manage the real organization and projcet via tfc_* modules.
#
# Required environment variables:
# TF_API_TOKEN, TF_CLOUD_ORGANIZATION, TF_CLOUD_EMAIL, TF_PROJECT, TF_WORKSPACE

set -euo pipefail

curla() {
    curl -sS \
        --header "Authorization: Bearer $TF_API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" $@
}

projectId () {
    PROJECTS=$(curla https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/projects)
    echo $PROJECTS | jq -r ".data[] | select(.attributes.name == \"$TF_PROJECT\").id"
}

# 🏢 Check if the organization exists
if curla -f -o /dev/null --head https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/workspaces; then
    echo "🏢 Organization exists."
else
    echo "🏢 Organization does not exist. Creating..."
    curla -o /dev/null -X POST --fail \
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

# 💼 Check if the project exists
if [ -z "$(projectId)" ]; then
    echo "💼 Project does not exist. Creating..."
    curla -o /dev/null -X POST --fail \
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

# 📋 Check if the workspace exists
if curla -o /dev/null --fail --head https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/workspaces/$TF_WORKSPACE; then
    echo "📋 Workspace exists."
else
    echo "📋 Workspace does not exist. Creating..."
    PROJECT_ID=$(projectId)
    curla -o /dev/null --fail -X POST https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/workspaces \
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

echo "All done."
