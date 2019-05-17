# dcos-demo-1.13
Basic Enterprise DC/OS 1.13 Demo for mixed workloads including Spark, Kafka, and Kubernetes

## USAGE

     $ git clone https://github.com/gregpalmr/dcos-demo-1.13

     $ cd dcos-demo-1.13

## 1. Setup

Before starting the demo session, perform the following steps:

- Install the prerequisites (AWS cli, MAWS, DC/OS cli, Kubernetes cli, Terraform, and ssh-keygen)
- Launch a DC/OS 1.13 cluster in AWS
- Prep the demo environment by starting Spark, Kafka and several Kubernetes clusters
- Create several HAProxy instances to proxy the Kubernetes cluster's API Servers
- Setup kubectl for interaction with several of the Kubernetes clusters
- Launch the Sock Shop microserves demo pods onto one of the Kubernetes clusters

### a. Install the Prerequisites

This demo environment requires several packages to be installed and working. Install them using these steps.

#### AWS cli

Install the AWS command line interface on a Mac using this command:

     $ brew install awscli

#### MAWS for AWS authentication

If you are a Mesosphere mesonaut, then you will have to use the Mesosphere version of MAWS. If you are not a mesonaut, then you can use some other means of setting up your AWS IAM environment.

See: https://github.com/mesosphere/maws 

     $ brew install maws

#### DC/OS cli

Install the DC/OS command line interface by following the instructions on the DC/OS Dashboard (upper right corner). On a Mac, it would be similar to these commands:

     $ [ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin && \
       curl https://downloads.dcos.io/binaries/cli/darwin/x86-64/dcos-1.13/dcos -o dcos && \
       sudo mv dcos /usr/local/bin && sudo chmod +x /usr/local/bin/dcos

     $ dcos cluster setup https://<master node public ip address>  

NOTE: You must use the HTTPS url and not the default HTTP url for the demo-prep.sh script to work (it checks for it).

#### Kubernetes cli

The Kubernetes command line interface (kubectl) can be installed on a Mac using these commands:

     $ brew install kubectl

#### Terraform cli

The Terraform command line interface can be installed on a Mac using these commands:

     $ brew install terraform

#### ssh-keygen and ssh-add

If your Mac does not have these utilities installed, call your IT helpdesk and ask for instructions on how to install them.

### b. Launch an Enterprise DC/OS cluster

Launch an Enterprise DC/OS cluster using the Mesosphere DC/OS Universal Installer. 

First modify the cluster/main.tf terraform template file to use your own unique cluster name. This is important because it will create objects in AWS that must have unique names. Also, make sure your DC/OS license file is available on your local computer and it is referenced correctly in the main.tf file.

     $ vi cluster/main.tf

     Change line: prefix = "mycluster-"

     Change line: dcos_license_key_contents = "${file("~/scripts/license.txt")}"

     Change line: owner = "Firstname Lastname"

The default AWS region is set to "US EAST 1". If you want to change the region and availability zones, change the following lines in the main.tf file:

     $ vi cluster/main.tf

     Change line: region = "us-east-1"

     Change line: availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

Then run the provided script to launch a DC/OS 1.13 cluster in AWS using the DC/OS Universal Installer:

     $ ./scripts/launch-cluster.sh

This script will do the following:

- Run the MAWS command to initialize an AWS cli session. It puts the results in:

     ~/.aws/credentials

- Generates a new public and private SSL key pair to be used to SSH into the AWS instances to be created. The keys are stored in:

     ~/.ssh/id_rsa-terraform 

     ~/.ssh/id_rsa-terraform.pub

- Runs the terraform commands against the cluster/main.tf template file to generate a plan and to apply the plan.

OR, follow the instructions here: https://github.com/dcos/terraform-dcos

     $ eval $(maws login 110465657741_Mesosphere-PowerUser)

     $ export AWS_DEFAULT_REGION="us-east-1"

     $ terraform init -upgrade=true && terraform plan -out plan.out && terraform apply plan.out

     $ terraform destroy

NOTE: Make sure your "main.tf" template includes at least the following:

-  1 DC/OS Master Node - with 4 vCPUs each
- 10 DC/OS Private Agent Nodes - with 8 vCPUs each
-  2 DC/OS Public Agent Nodes - with 4 vPCUs each

### c. Login to the Enterprise DC/OS Dashboard

Point your web browser to DC/OS master node and login as the default superuser (bootstrapuser/deleteme). The master node Dashboard URL is:

    https://<master node public ip address>

### d. Install the DC/OS command line interface (CLI)

In the DC/OS Dashboard, click on the drop down menu in the upper right side of the dashboard and follow the instructions for installing the DC/OS CLI binary for your OS.

Then run the cluster setup command:

    $ dcos cluster setup https://<master node public ip address>

NOTE: Make sure you use an HTTPS URL in the cluster setup command and not an HTTP URL.

Once the DC/OS CLI is installed, install some sub-commands. This is optional if you run the scripts/prep-cluster.sh script.

    $ dcos package install --cli spark --yes

    $ dcos package install --cli kafka --yes

    $ dcos package install --cli kubernetes --yes

    $ dcos package install dcos-enterprise-cli --yes

### e. Prep the Cluster

To support launching Kubernetes clusters with DC/OS service accounts and SSL certificates, run the prep script that creates the base service account users and their signed certificates using the DC/OS certificate authority (CA). This script also launches 4 example MKE kubernetes clusters (with their api-server proxies) as well as the Spark dispatcher and a Kafka service.

    $ scripts/prep-cluster.sh

This script will do the following:

- Create DC/OS service account users for k8s-1 through k8s-5 along with thier DC/OS permissions.
- Create DC/OS secrets with SSL certificates for the above users to be used for enabling TLS.
- Launch the MKE Kubernetes control plane manager (catalog package: Kubernetes).
- Launch four example MKE Kubernetes Clusters (catalog package: Kubernetes Cluster). These clusters will have varying Kubernetes version numbers and will be spread across three availability zones to demonstration high density kubernetes and zone awareness.
- Call the scripts/start-proxies.sh script to launch two HAProxy services to proxy the Kubernetes API Server objects for two of the MKE Kubernetes clusters (k8s-1 and k8s-2).
- Call the scripts/setup-kubectl.sh script to setup the Kubernetes cli (kubectl) for two of the MKE Kubernetes clusters (k8s-1 and k8s2) and launch a Chrome browser session for the Kubernetes Dashboard for the k8s-1 cluster.
- Call the scripts/start-sockshop-pods.sh script to start the Sock Shop microservices demo into pods in the k8s-1 cluster and to launch a Chrome browser session for the Sock Shop shopping cart web page.

### f. Get the public IP addresses of the DC/OS public agent nodes. 

As part of the demo, you will need to access the public MKE Kubernetes nodes running on the public DC/OS agent nodes. Use the following command to get the public IP address of those DC/OS public agent nodes.

    $ scripts/get-dcos-public-agent-ip.sh 2

NOTE: This is done for you at the end of the prep-cluster.sh script, so you can see the public ip address at the end of the output.

## 2. Demo

### a. DC/OS Overview

Before starting the demo, discuss with the audience what you are going to demonstrate in the next few minutes.

Show the main DC/OS Dashboard and talk about how DC/OS pools resources (CPU, GPU, Memory and Disk) and allocates them dynamically to services that are launched from the Catalog or the Services panel.

Show the Nodes panel and show the servers that are being managed by DC/OS. Discuss how DC/OS is region and zone aware (or rack aware when on-prem) and how workloads can be launched with "placement constraints" to spread them across fault zones.

Show the Components panel and show how all the ecosystem components that are used to manage the cluster and how DC/OS automates the health of those low level components.

Show the Catalog panel and show how pre-packages applications and services can be launched easily from the package catalog and how customers can add their own packages using the DC/OS Universe github repo tools (see https://github.com/mesosphere/universe). Show the Settings->Package Reposities panel and discus how customers can add their own repos behind their firewall for private use.

### b. Demonstrate starting mixed workloads including:

- Jenkins
- Kafka
- Spark
- Cassandra

The prep-cluster.sh script starts an example Spark distpatcher and Kafka service, but at this time use the Catalog to start a Jenksins service. Talk about how the Jenkins service can take advantage of DC/OS's support for persistant storage volumes and how the Jenkins console can be access via the DC/OS Admin Router (authenticated web proxy) component.

When Jenkins starts up, show the Jenkins Console and discuss how customers can use the console or the Jenkins API to setup and manage build/test pipelines.

Demonstrate the Spark dispatcher service. Show the Spark console and discuss how multiple Spark environments (with different versions) can be launced for different teams and how DC/OS access control lists can be used to keep the teams separate.  You can run a sample Spark job buy using the 'dcos spark run' command as shown in the file:

    examples/spark-examples.txt

### c. Demonstrate starting multiple Kubernets Clusters

Discuss how Enterprise DC/OS supports "high density" kubernetes clusters and supports launching different versions of Kubernetes clusters to support different development teams. And how DC/OS uses an un-forked version of the opensource version of Kubernetes and the kubectl package. And how DC/OS allows kubernetes control plan components and worker node components to be spread across cloud availability zones for HA reasons. Use the Dashboard's Services panel to show how the example MKE clusters are running tasks that are spread across availability zones and how (with high density Kubernetes support), DC/OS is running tasks from multiple Kubernetes clusters on the SAME servers or cloud instances!

Use the DC/OS Dashboard Catalog panel to start a 5th Kubernetes cluster. Specify the service account user and secrets like this:

    Package: kubernetes-cluster
    Version: 2.2.2-1.13.5 (an older version)
    Options:
        Service Name: k8s-5 
        Service Account:  k8s-5
        Service Account Secret: k8s-5/sa
        Placement: Number of Zones: 2 
        Private Node Count: 1
        Public Node Count: 0

Talk about how MKE can implement Kubernetes RBAC with the click of a checkbox and how it can enable HA too (in fact k8s-1 cluster is deployed in HA mode).

### d. Demonstrate the Enterprise DC/OS features

While the two Kubernets clusters are launching, use the DC/OS Dashboard to show how DC/OS:

- Integrates with LDAP/AD servers
- Integrates with SAML 2.0 and OAuth2 authention servers
- Supports encrypted secrets

Create two user groups (mobile-apps and enterprise-apps), then create a user and add it to the mobile-apps group.

Add ACL rules to the mobile-apps group by copying the contents of:

    examples/acl-examples.txt

into the Permissions panel for the mobile-apps group.

Then log off as the super user and log in as the user you created. Show how many of the left side menu options are missing and try to start a MySQL package in the application group:

    /enterprise-apps/mysql

Show how DC/OS does not allow the user to start MySQL into that application group. Then change it to the group:

    /mobile-apps/mysql

And show how DC/OS allows that and by looking at the Services panel, how the MySQL package is "deploying".

### e. Demonstrate kubctl commands

The prep-cluser.sh script called the setup-kubectl.sh script which setup the kubectl command pointing to the k8s-1 cluster. Additionally the start-sockshop-pods.sh script was called to load the sockshop microservices example application running with nodeport functionality in Kubernetes pods. Point your web browser to one of the DC/OS public agent nodes running and point to the Sockshop shopping cart example app:

    http://<public agent public ip address>:30001

You can also demonstrate interacting with the Kubernetes cluster using other  kubectl commands. Some example kubectl commands can be found in:

    examples/kubectl-examples.txt

If you want to demonstrate installing Helm and a Heml Chart, you can experiment with the commands found in:

    examples/helm-examples.txt

### f. Demonstrate upgrading a Kubernetes cluster

Discuss how Enterprise DC/OS automates the process of upgrading, in a rolling fashion, the upgrading of Kubernetes clusters without disrupting the pods running on the Kubernetes cluster. Also, discuss how DC/OS has a built-in CLI command that can backup the Kubernetes cluster meta-data (from the etcd daemons) so that a Kubernetes cluster's state can be restored from a backup in the case of a failure or building a new Kubernetes cluster.

Use the DC/OS CLI to upgrade the second Kubernetes cluster from 1.13.5 to the latest release (1.14.1 as of this time). The upgrade commands can be found in an example file at:

    examples/kubernetes-upgrade-example.txt

Use the following commands to upgrade the second Kubernetes cluster:

    $ dcos package install kubernetes --cli --package-version=2.3.0-1.14.1 --yes

    $ dcos kubernetes cluster update  --cluster-name=k8s-1 --package-version=2.3.0-1.14.1 --yes

Go to the DC/OS Dashboard and display the "Plans" page for the k8s-1 kubernetes cluster and show the progression of the upgrade.

Show the DC/OS Dashboard Service panel and how the Kubernetes-cluster2 processes are restarting in a rolling fashion.

## 3. Summarize what you demonstrated

Summarize, for the audience, what you just demonstrated and how it can help customers deploy applications and services in a hybrid cloud environment with ease.

## 4. Shutdown the Services used in the Demo

To reset the DC/OS cluster to a new state, run the script:

     $ scripts/reset-demo.sh

## 5. Destroy the DC/OS cluster

To destroy the DC/OS cluster that was launched by the Mesosphere DC/OS Universal Installer, run this script:

     $ scripts/destroy-cluster.sh

## TODO

- Add a short demo of killing a Kubernetes process and watching DC/OS automatically restarting it.

- Add an example of a pod running in a Kubernetes cluster making consumer/producer calls to the Kafka service running in native DC/OS.

- Add a short DC/OS Monitoring (prometheus/graphana) demo.


