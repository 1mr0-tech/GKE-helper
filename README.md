# GKE Tool - Your Friendly GKE Cluster Manager

```
 ██████╗ ███████╗███╗   ███╗██╗███╗   ██╗██╗  ██████╗██╗     ██╗
██╔════╝ ██╔════╝████╗ ████║██║████╗  ██║██║ ██╔════╝██║     ██║
██║  ███╗█████╗  ██╔████╔██║██║██╔██╗ ██║██║ ██║     ██║     ██║
██║   ██║██╔══╝  ██║╚██╔╝██║██║██║╚██╗██║██║ ██║     ██║     ██║
╚██████╔╝███████╗██║ ╚═╝ ██║██║██║ ╚████║██║ ╚██████╗███████╗██║
 ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═════╝╚══════╝╚═╝
```

A simple, menu-driven bash script to make managing your Google Kubernetes Engine (GKE) clusters easier and more efficient. This tool was developed with the help of the Gemini CLI to streamline common DevOps tasks and reduce the need to remember complex `kubectl` commands.

## Features

*   **Interactive Menus:** A user-friendly, menu-driven interface for all operations.
*   **Prerequisite Checker:** Automatically checks for required tools (`gcloud`, `kubectl`, `gke-gcloud-auth-plugin`) and provides installation instructions if they are missing.
*   **Cluster Analysis:** Get cluster info, list nodes, and view all pods across all namespaces.
*   **Deployment Management:** List, describe, scale, and restart deployments with ease.
*   **Pod Management:** View and stream logs from pods, and execute commands in them.
*   **Service Management:** List and describe services in your cluster.
*   **Resource Management:** Manage ConfigMaps and Secrets, including creation from files.
*   **Performance Dashboard:** A real-time, terminal-based dashboard of your cluster's resource usage, with pods grouped by namespace.
*   **Formatted Output:** Clean, aligned output for better readability.

## Prerequisites

Before using the tool, you need to have the following installed and configured on your system:

*   **Google Cloud SDK:** The `gcloud` command-line tool.
*   **kubectl:** The Kubernetes command-line tool.
*   **gke-gcloud-auth-plugin:** The GKE authentication plugin for `kubectl`.

The script will automatically check for these prerequisites and guide you through the installation process if any are missing.

## Installation and Usage

1.  **Clone the repository:**
    ```bash
    git clone <your-repo-url>
    cd <your-repo-name>
    ```

2.  **Make the script executable:**
    ```bash
    chmod +x gke-tool.sh
    ```

3.  **Run the script:**
    ```bash
    ./gke-tool.sh
    ```

The script will then guide you through the process of connecting to your GKE cluster and provide you with a menu of options to choose from.

## Sample Workflow

Here is a sample workflow demonstrating the key features of the tool:

```
Welcome to the gke-tool! This is a sample workflow demonstrating its key features.

--- Step 1: Initial Run & Prerequisite Check ---

$ ./gke-tool.sh
[INFO] Checking for required tools and configuration...
[INFO] It's recommended to keep gcloud components up-to-date.
Would you like to run 'gcloud components update'? (y/N): n
[SUCCESS] All required tools are installed and configured correctly.

--- Step 2: Connecting to the Cluster ---

[INFO] Please enter your GKE cluster details.
Cluster Name: gemini-demo-cluster
Project ID: gemini-dev-project
Location (e.g., us-central1 or us-central1-c): us-east1-b
[INFO] Connecting to GKE cluster...
Fetching cluster endpoint and auth data.
kubeconfig entry "gemini-demo-cluster" generated.
[SUCCESS] Successfully connected to the cluster.

--- Step 3: Main Menu ---

GKE Cluster Operations Menu:
1.  Analyse Cluster
2.  Manage Deployments
3.  Manage Pods
4.  Manage Services
5.  Manage Resources (ConfigMaps, Secrets)
6.  Performance Dashboard
q.  Quit
Enter your choice: 1

--- Step 4: Analyzing the Cluster ---

Analyse Cluster Menu:
1.  Get cluster info
2.  List all nodes
3.  List all pods in all namespaces
4.  Get cluster resource usage (top nodes/pods)
b.  Back to main menu
Enter your choice: 2

NAME                                     STATUS   ROLES    AGE   VERSION
gke-gemini-demo-cluster-default-pool-123   Ready    <none>   99d   v1.25.5-gke.2500
gke-gemini-demo-cluster-default-pool-456   Ready    <none>   99d   v1.25.5-gke.2500

--- Step 5: Managing Deployments ---

Enter your choice: b

GKE Cluster Operations Menu:
...
Enter your choice: 2

[INFO] Fetching namespaces...
Available Namespaces:
1) default
2) dev-namespace
3) prod-namespace
4) kube-system
#? 2

Manage Deployments in 'dev-namespace' Menu:
1.  List deployments
2.  Describe a deployment
...
b.  Back to main menu
Enter your choice: 1

NAME           READY   UP-TO-DATE   AVAILABLE   AGE
frontend-app   2/2     2            2           42d
backend-api    3/3     3            3           60d

Enter your choice: 2

[INFO] Fetching deployment in namespace 'dev-namespace'...
Available deployments:
1) frontend-app
2) backend-api
#? 1

Describing deployment "frontend-app"...
(kubectl describe output would be displayed here)

--- Step 6: Viewing Pod Logs ---

Enter your choice: b

GKE Cluster Operations Menu:
...
Enter your choice: 3

[INFO] Fetching namespaces...
Available Namespaces:
...
#? 2

Manage Pods in 'dev-namespace' Menu:
1.  View logs
2.  Execute a command in a pod
b.  Back to main menu
Enter your choice: 1

[INFO] Fetching pod in namespace 'dev-namespace'...
Available pods:
1) frontend-app-6b4f8f9d4-abcde
2) frontend-app-6b4f8f9d4-fghij
3) backend-api-7c5g9g0d5-klmno
4) backend-api-7c5g9g0d5-pqrst
5) backend-api-7c5g9g0d5-uvwxy
#? 1

Select a container to view logs:
1) nginx
2) sidecar-proxy
#? 1

Log options:
1. View current logs
2. Stream logs (-f)
3. View previous logs (-p)
Enter your choice: 2

(Log streaming output would appear here...)

--- Step 7: Creating a Resource ---

(Ctrl+C to stop streaming)
Enter your choice: b

GKE Cluster Operations Menu:
...
Enter your choice: 5

Resource Management Menu:
1. Manage ConfigMaps
2. Manage Secrets
b. Back to main menu
Enter your choice: 1

[INFO] Fetching namespaces...
...
#? 2

Manage ConfigMaps in 'dev-namespace' Menu:
...
3. Create a ConfigMap
...
Enter your choice: 3

Enter ConfigMap name: api-endpoints
Create ConfigMap from:
1. Literal values
2. File
Enter your choice: 1

Enter data (e.g., key1=value1,key2=value2): auth-url=http://auth-service,user-url=http://user-service
configmap/api-endpoints created

--- Step 8: Quitting the Tool ---

Enter your choice: b
Enter your choice: b
Enter your choice: q
[INFO] Exiting GKE tool.
$
```
