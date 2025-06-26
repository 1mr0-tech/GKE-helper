#!/bin/bash

# gke-tool.sh: A tool to simplify GKE cluster operations.

# --- Configuration ---
# Set to "true" to enable debug mode
DEBUG=false

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---
function print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

function print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

function print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

function print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

function debug() {
    if [ "$DEBUG" = "true" ]; then
        echo -e "${YELLOW}[DEBUG]${NC} $1"
    fi
}

# New helper function to format output
function format_output() {
    column -t -s "   "
}

# New helper function to select a namespace
function select_namespace() {
    print_info "Fetching namespaces..."
    local namespaces=$(kubectl get namespace -o custom-columns=NAME:.metadata.name --no-headers)
    echo "Available Namespaces:"
    select ns in $namespaces; do
        if [ -n "$ns" ]; then
            echo "$ns"
            return
        else
            print_warning "Invalid selection. Please try again."
        fi
    done
}

# New helper function to select a resource
function select_resource() {
    local resource_type=$1
    local namespace=$2
    
    print_info "Fetching ${resource_type}s in namespace '$namespace'..."
    local resources=$(kubectl get $resource_type -n $namespace -o custom-columns=NAME:.metadata.name --no-headers)
    
    if [ -z "$resources" ]; then
        print_warning "No ${resource_type}s found in namespace '$namespace'."
        return 1
    fi

    echo "Available ${resource_type}s:"
    select resource in $resources; do
        if [ -n "$resource" ]; then
            echo "$resource"
            return
        else
            print_warning "Invalid selection. Please try again."
        fi
    done
}

function usage() {
    echo "Usage: $0"
    echo "This tool will prompt you for the GKE cluster details."
    exit 1
}

function performance_dashboard_menu() {
    # Trap Ctrl+C to return to the main menu
    trap 'trap - INT; return' INT

    while true; do
        clear
        echo -e "${BLUE}Cluster Performance Dashboard (by Namespace)${NC}"
        echo "Refreshes automatically every 15 seconds. Press Ctrl+C to return to the menu."
        echo -e "${YELLOW}----------------------------------------------------------------------${NC}"

        # Overall Node Status
        echo -e "\n${GREEN}Node Resource Usage:${NC}"
        kubectl top nodes | format_output

        echo -e "\n${GREEN}Pod Resource Usage by Namespace:${NC}"

        # Get all namespaces
        namespaces=$(kubectl get namespace -o custom-columns=NAME:.metadata.name --no-headers)

        for ns in $namespaces; do
            # Get top pods for the namespace, hiding errors if metrics-server is not available for it
            output=$(kubectl top pods -n "$ns" 2>/dev/null)
            # Check if the output contains more than just the header
            if [[ -n "$output" && $(echo "$output" | wc -l) -gt 1 ]]; then
                echo -e "\n${YELLOW}Namespace: $ns${NC}"
                echo "$output" | format_output
            fi
        done
        sleep 15
    done

    # Restore the default interrupt signal handling
    trap - INT
}

function check_prerequisites() {
    print_info "Checking for required tools and configuration..."

    # 1. Check for gcloud and get SDK root
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud SDK ('gcloud') is not installed or not in your PATH."
        # Provide installation instructions
        # ... (instructions from previous steps) ...
        exit 1
    fi
    
    # Get the SDK root path from gcloud itself
    local sdk_root=$(gcloud info --format="value(installation.sdk_root)")
    local sdk_bin_path="$sdk_root/bin"

    # 2. Check for kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "'kubectl' is not installed or not in your PATH."
        # Provide installation instructions
        # ... (instructions from previous steps) ...
        exit 1
    fi

    # 3. Check for gke-gcloud-auth-plugin
    local plugin_path="$sdk_bin_path/gke-gcloud-auth-plugin"
    if [ ! -f "$plugin_path" ]; then
        print_error "The 'gke-gcloud-auth-plugin' is not installed."
        echo -e "Please run the following command to install it:\n"
        echo -e "${YELLOW}   gcloud components install gke-gcloud-auth-plugin${NC}\n"
        exit 1
    fi

    # 4. Check if the SDK bin path is in the system PATH
    if [[ ":$PATH:" != *":$sdk_bin_path:"* ]]; then
        print_warning "The Google Cloud SDK bin directory is not in your PATH."
        print_info "Temporarily adding it to the PATH for this session."
        export PATH="$sdk_bin_path:$PATH"
        
        echo -e "\nTo fix this permanently, add the following line to your shell profile file (e.g., ~/.zshrc, ~/.bashrc, or ~/.bash_profile):"
        echo -e "${YELLOW}export PATH=\"\$PATH:$sdk_bin_path\"${NC}"
        print_info "After adding it, restart your shell or run 'source ~/.your_profile_file'."
    fi

    print_success "All required tools are installed and configured correctly."
}

# --- Main Logic ---
function main() {
    check_prerequisites

    print_info "Please enter your GKE cluster details."
    read -p "Cluster Name: " cluster_name
    read -p "Project ID: " project_id
    read -p "Location (e.g., us-central1 or us-central1-c): " location

    local location_flag
    if [[ "$location" =~ ^[a-z]+-[a-z]+[0-9]+$ ]]; then
        location_flag="--region"
    else
        location_flag="--zone"
    fi

    print_info "Connecting to GKE cluster..."
    if ! gcloud container clusters get-credentials "$cluster_name" --project "$project_id" "$location_flag" "$location"; then
        print_error "Failed to connect to GKE cluster. Please check your details and permissions."
        exit 1
    fi
    print_success "Successfully connected to the cluster."

    # --- Interactive Menu ---
    while true; do
        echo -e "\n${BLUE}GKE Cluster Operations Menu:${NC}"
        echo "1.  Analyse Cluster"
        echo "2.  Manage Deployments"
        echo "3.  Manage Pods"
        echo "4.  Manage Services"
        echo "5.  Manage Resources (ConfigMaps, Secrets)"
        echo "6.  Performance Dashboard"
        echo "q.  Quit"

        read -p "Enter your choice: " choice

        case "$choice" in
            1) analyse_cluster_menu ;;
            2) manage_deployments_menu ;;
            3) manage_pods_menu ;;
            4) manage_services_menu ;;
            5) manage_resources_menu ;;
            6) performance_dashboard_menu ;;
            q) break ;;
            *) print_warning "Invalid option. Please try again." ;;
        esac
    done

    print_info "Exiting GKE tool."
}

# --- Menu Functions ---
function analyse_cluster_menu() {
    while true; do
        echo -e "\n${BLUE}Analyse Cluster Menu:${NC}"
        echo "1.  Get cluster info"
        echo "2.  List all nodes"
        echo "3.  List all pods in all namespaces"
        echo "4.  Get cluster resource usage (top nodes/pods)"
        echo "b.  Back to main menu"

        read -p "Enter your choice: " choice

        case "$choice" in
            1) kubectl cluster-info | format_output ;;
            2) kubectl get nodes -o wide | format_output ;;
            3) kubectl get pods --all-namespaces -o wide | format_output ;;
            4) echo "Top Nodes:" && kubectl top nodes | format_output && echo "Top Pods:" && kubectl top pods --all-namespaces | format_output ;;
            b) break ;;
            *) print_warning "Invalid option. Please try again." ;;
        esac
    done
}

function manage_deployments_menu() {
    local ns=$(select_namespace)
    [ -z "$ns" ] && return

    while true; do
        echo -e "\n${BLUE}Manage Deployments in '$ns' Menu:${NC}"
        echo "1.  List deployments"
        echo "2.  Describe a deployment"
        echo "3.  Scale a deployment"
        echo "4.  Check rollout status"
        echo "5.  Restart a deployment"
        echo "b.  Back to main menu"

        read -p "Enter your choice: " choice

        case "$choice" in
            1) kubectl get deployments -n $ns -o wide | format_output ;;
            2) local dep=$(select_resource "deployment" $ns) && [ -n "$dep" ] && kubectl describe deployment $dep -n $ns ;;
            3) local dep=$(select_resource "deployment" $ns) && [ -n "$dep" ] && read -p "Enter replica count: " replicas && kubectl scale deployment $dep -n $ns --replicas=$replicas ;;
            4) local dep=$(select_resource "deployment" $ns) && [ -n "$dep" ] && kubectl rollout status deployment $dep -n $ns ;;
            5) local dep=$(select_resource "deployment" $ns) && [ -n "$dep" ] && kubectl rollout restart deployment $dep -n $ns ;;
            b) break ;;
            *) print_warning "Invalid option. Please try again." ;;
        esac
    done
}

function manage_pods_menu() {
    local ns=$(select_namespace)
    [ -z "$ns" ] && return

    while true; do
        echo -e "\n${BLUE}Manage Pods in '$ns' Menu:${NC}"
        echo "1.  View logs"
        echo "2.  Execute a command in a pod"
        echo "b.  Back to main menu"

        read -p "Enter your choice: " choice

        case "$choice" in
            1) view_pod_logs "$ns" ;;
            2) local pod=$(select_resource "pod" $ns) && [ -n "$pod" ] && kubectl exec -it $pod -n $ns -- /bin/sh ;;
            b) break ;;
            *) print_warning "Invalid option. Please try again." ;;
        esac
    done
}

function view_pod_logs() {
    local ns=$1
    local pod=$(select_resource "pod" $ns)
    [ -z "$pod" ] && return

    local containers=$(kubectl get pod $pod -n $ns -o jsonpath='{.spec.containers[*].name}')
    local container_to_log=""

    if [ $(echo $containers | wc -w) -gt 1 ]; then
        echo "Select a container to view logs:"
        select c in $containers; do
            if [ -n "$c" ]; then
                container_to_log="-c $c"
                break
            else
                print_warning "Invalid selection."
            fi
        done
    fi

    echo -e "\nLog options:"
    echo "1. View current logs"
    echo "2. Stream logs (-f)"
    echo "3. View previous logs (-p)"
    read -p "Enter your choice: " log_choice

    case "$log_choice" in
        1) kubectl logs $pod -n $ns $container_to_log ;;
        2) kubectl logs -f $pod -n $ns $container_to_log ;;
        3) kubectl logs -p $pod -n $ns $container_to_log ;;
        *) print_warning "Invalid option." ;;
    esac
}

function manage_services_menu() {
    local ns=$(select_namespace)
    [ -z "$ns" ] && return

    while true; do
        echo -e "\n${BLUE}Manage Services in '$ns' Menu:${NC}"
        echo "1.  List services"
        echo "2.  Describe a service"
        echo "b.  Back to main menu"

        read -p "Enter your choice: " choice

        case "$choice" in
            1) kubectl get services -n $ns -o wide | format_output ;;
            2) local svc=$(select_resource "service" $ns) && [ -n "$svc" ] && kubectl describe service $svc -n $ns ;;
            b) break ;;
            *) print_warning "Invalid option. Please try again." ;;
        esac
    done
}

function manage_resources_menu() {
    while true; do
        echo -e "\n${BLUE}Resource Management Menu:${NC}"
        echo "1. Manage ConfigMaps"
        echo "2. Manage Secrets"
        echo "b. Back to main menu"

        read -p "Enter your choice: " choice

        case "$choice" in
            1) manage_configmaps_menu ;;
            2) manage_secrets_menu ;;
            b) break ;;
            *) print_warning "Invalid option. Please try again." ;;
        esac
    done
}

function manage_configmaps_menu() {
    local ns=$(select_namespace)
    [ -z "$ns" ] && return

    while true; do
        echo -e "\n${BLUE}Manage ConfigMaps in '$ns' Menu:${NC}"
        echo "1. List ConfigMaps"
        echo "2. Describe a ConfigMap"
        echo "3. Create a ConfigMap"
        echo "4. Delete a ConfigMap"
        echo "b. Back to resource menu"

        read -p "Enter your choice: " choice

        case "$choice" in
            1) kubectl get configmaps -n $ns -o wide | format_output ;;
            2) local cm=$(select_resource "configmap" $ns) && [ -n "$cm" ] && kubectl describe configmap $cm -n $ns ;;
            3) create_configmap_menu "$ns" ;;
            4) local cm=$(select_resource "configmap" $ns) && [ -n "$cm" ] && kubectl delete configmap $cm -n $ns ;;
            b) break ;;
            *) print_warning "Invalid option. Please try again." ;;
        esac
    done
}

function create_configmap_menu() {
    local ns=$1
    read -p "Enter ConfigMap name: " name
    
    echo "Create ConfigMap from:"
    echo "1. Literal values"
    echo "2. File"
    read -p "Enter your choice: " create_choice

    case "$create_choice" in
        1) read -p "Enter data (e.g., key1=value1,key2=value2): " data && kubectl create configmap "$name" -n "$ns" --from-literal="$data" ;;
        2) read -p "Enter file path: " file_path && kubectl create configmap "$name" -n "$ns" --from-file="$file_path" ;;
        *) print_warning "Invalid option." ;;
    esac
}

function manage_secrets_menu() {
    local ns=$(select_namespace)
    [ -z "$ns" ] && return

    while true; do
        echo -e "\n${BLUE}Manage Secrets in '$ns' Menu:${NC}"
        echo "1. List Secrets"
        echo "2. Describe a Secret"
        echo "3. Create a generic Secret"
        echo "4. Delete a Secret"
        echo "b. Back to resource menu"

        read -p "Enter your choice: " choice

        case "$choice" in
            1) kubectl get secrets -n $ns -o wide | format_output ;;
            2) local secret=$(select_resource "secret" $ns) && [ -n "$secret" ] && kubectl describe secret $secret -n $ns ;;
            3) create_secret_menu "$ns" ;;
            4) local secret=$(select_resource "secret" $ns) && [ -n "$secret" ] && kubectl delete secret $secret -n $ns ;;
            b) break ;;
            *) print_warning "Invalid option. Please try again." ;;
        esac
    done
}

function create_secret_menu() {
    local ns=$1
    read -p "Enter Secret name: " name

    echo "Create Secret from:"
    echo "1. Literal values"
    echo "2. File"
    read -p "Enter your choice: " create_choice

    case "$create_choice" in
        1) read -p "Enter data (e.g., key1=value1,key2=value2): " data && kubectl create secret generic "$name" -n "$ns" --from-literal="$data" ;;
        2) read -p "Enter file path: " file_path && kubectl create secret generic "$name" -n "$ns" --from-file="$file_path" ;;
        *) print_warning "Invalid option." ;;
    esac
}


# --- Entry Point ---
main "$@"
