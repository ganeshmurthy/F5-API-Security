#!/bin/bash

set -e

# Function to display usage information
usage() {
    echo "F5 AI Security Deployment Script"
    echo "=================================================="
    echo ""
    echo "USAGE:"
    echo "  $0 [namespace]"
    echo "  $0 --help | -h"
    echo ""
    echo "PARAMETERS:"
    echo "  namespace    OpenShift namespace to deploy to (optional)"
    echo "               Default: f5-ai-security"
    echo "  --help, -h   Show this help message and exit"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                    # Deploy to default namespace (f5-ai-security)"
    echo "  $0 my-namespace       # Deploy to custom namespace"
    echo "  $0 production-f5      # Deploy to production namespace"
    echo ""
    echo "PREREQUISITES:"
    echo "  - OpenShift CLI (oc) installed and logged in"
    echo "  - Helm CLI installed"
    echo "  - Valid Hugging Face token (only for internal model deployments)"
    echo "  - At least one model configured (internal or external)"
    echo ""
    echo "LLM CONFIGURATION:"
    echo "  Configure LLM settings via the web UI after deployment:"
    echo "  • XC URL: Set the chat completions endpoint"
    echo "  • Model ID: Specify the model to use"
    echo "  • API Key: Add authentication if required"
    echo ""
    echo "  Available pre-defined models:"
    echo "  - llama-3-2-1b-instruct, llama-3-1-8b-instruct"
    echo "  - llama-3-2-3b-instruct, llama-3-3-70b-instruct"
    echo "  - llama-guard-3-1b, llama-guard-3-8b"
    echo "  - qwen-2-5-vl-3b-instruct, llama-3-2-1b-instruct-quantized"
    echo ""
}

# Check for help option first
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    usage
    exit 0
fi

# Parse command line arguments, default namespace to f5-ai-security if not provided.
NAMESPACE="${1:-f5-ai-security}"

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CHART_DIR="${SCRIPT_DIR}/f5-ai-security"
VALUES_FILE="${SCRIPT_DIR}/f5-ai-security-values.yaml"
EXAMPLE_FILE="${SCRIPT_DIR}/f5-ai-security-values.yaml.example"

# Display deployment info
echo "F5 AI Security Deployment"
echo "========================="
echo "Target namespace: ${NAMESPACE}"
echo ""

# Function to check if a command exists
check_command() {
    local cmd=$1
    local description=$2
    
    if command -v "$cmd" &> /dev/null; then
        echo "$description - $(which $cmd)"
        return 0
    else
        echo "$description not found"
        return 1
    fi
}

# Function to check OpenShift login status
check_openshift_login() {
    if oc whoami &> /dev/null; then
        local user=$(oc whoami)
        local server=$(oc whoami --show-server 2>/dev/null || echo "unknown")
        echo "OpenShift Login - User: $user"
        echo "Server: $server"
        return 0
    else
        echo "Not logged into OpenShift"
        echo "Login with: oc login --server=<your-cluster> --token=<your-token>"
        return 1
    fi
}

# Function to check Helm repositories
check_helm_repos() {
    local repo_url="https://rh-ai-quickstart.github.io/ai-architecture-charts"
    
    if helm repo list 2>/dev/null | grep -q "$repo_url"; then
        echo "Helm Repository - rh-ai-quickstart repo found"
        return 0
    else
        echo "Helm Repository - rh-ai-quickstart repo not found"
        echo " Adding repository..."
        if helm repo add rh-ai-quickstart "$repo_url" &> /dev/null; then
            helm repo update &> /dev/null
            echo " Repository added successfully"
            return 0
        else
            echo " Failed to add Helm repository"
            return 1
        fi
    fi
}

# Function to check all prerequisites
check_prerequisites() {
    echo ""
    echo "Checking Prerequisites..."
    echo "----------------------------------------"

    # Track if all prerequisites are met
    local PREREQS_OK=true

    # Check required CLI tools oc and helm
    check_command "oc" "OpenShift CLI (oc)" || PREREQS_OK=false
    check_command "helm" "Helm CLI" || PREREQS_OK=false

    # Check OpenShift login
    check_openshift_login || PREREQS_OK=false

    # Check Helm repositories
    check_helm_repos || PREREQS_OK=false

    # Exit if prerequisites are not met
    if [ "$PREREQS_OK" = false ]; then
        echo ""
        echo "Prerequisites check failed!"
        echo "Please install missing tools and login to OpenShift before running this script."
        exit 1
    fi

    echo "Proceeding with deployment..."
}

# Run prerequisites check
check_prerequisites

# LLM Configuration
echo ""
echo "LLM Configuration"
echo "================="
echo "LLM settings can be configured via the web UI after deployment:"
echo "• Navigate to the application URL"
echo "• Use the left sidebar to configure XC URL, Model ID, and API Key"
echo "• Changes take effect immediately for your session"
echo ""

# Check if values file exists, if not copy from example
if [ ! -f "${VALUES_FILE}" ]; then
    echo "Values file not found: ${VALUES_FILE}"
    echo "Copying from example: ${EXAMPLE_FILE}"
    cp "${EXAMPLE_FILE}" "${VALUES_FILE}"
    echo "Created ${VALUES_FILE}"
    echo "Please edit this file to configure your deployment (API keys, model selection, etc.)"
    echo ""
fi

echo "Ready to deploy with default configuration."
echo "LLM settings will be configurable via the web UI after deployment."

echo "Updating Helm dependencies..."
helm dependency update "${CHART_DIR}"

echo "Creating OpenShift project ${NAMESPACE}..."
oc new-project "${NAMESPACE}" || echo "Project already exists, continuing..."

echo "Installing f5-ai-security Helm chart with custom values..."

# Build Helm command
HELM_ARGS="-f ${VALUES_FILE}"

# Execute Helm install with all arguments
helm install f5-ai-security "${CHART_DIR}" $HELM_ARGS -n "${NAMESPACE}"

echo "Deployment complete!"
