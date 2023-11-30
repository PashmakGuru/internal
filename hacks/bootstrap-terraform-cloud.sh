#!/bin/bash
#
# Bootstrap Terraform Cloud
# Create an organization, project, and workflow that's designed to
# enable our other TFC codes to apply, i.e. it makes us able to
# manage the real organization and projcet via tfc_* modules.
#
# Required environment variables:
# TFC_API_TOKEN, ORG_NAME, ORG_EMAIL, PROJECT_NAME, WORKSPACE_NAME

set -euo pipefail

curla() {
    curl -sS \
        --header "Authorization: Bearer $TFC_API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" $@
}

projectId () {
    PROJECTS=$(curla https://app.terraform.io/api/v2/organizations/$ORG_NAME/projects)
    echo $PROJECTS | jq -r ".data[] | select(.attributes.name == \"$PROJECT_NAME\").id"
}

# 🏢 Check if the organization exists
if curla -f -o /dev/null --head https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces; then
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
            "name": "$ORG_NAME",
            "email": "$ORG_EMAIL"
        }
    }
}
REQUEST_BODY
fi

# 💼 Check if the project exists
if [ -z "$(projectId)" ]; then
    echo "💼 Project does not exist. Creating..."
    curla -o /dev/null -X POST --fail \
        https://app.terraform.io/api/v2/organizations/$ORG_NAME/projects \
        --data @- << REQUEST_BODY
{
    "data": {
        "attributes": {
            "name": "$PROJECT_NAME"
        },
        "type": "projects"
    }
}
REQUEST_BODY
else
    echo "💼 Project exists."
fi

# 📋 Check if the workspace exists
if curla -o /dev/null --fail --head https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces/$WORKSPACE_NAME; then
    echo "📋 Workspace exists."
else
    echo "📋 Workspace does not exist. Creating..."
    PROJECT_ID=$(projectId)
    curla -o /dev/null --fail -X POST https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces \
        --data @- << REQUEST_BODY
{
    "data": {
        "attributes": {
            "name": "$WORKSPACE_NAME",
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
