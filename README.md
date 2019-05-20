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

### A. Install the Prerequisites

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

### B. Launch an Enterprise DC/OS cluster

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

### C. Login to the Enterprise DC/OS Dashboard

Point your web browser to DC/OS master node and login as the default superuser (bootstrapuser/deleteme). The master node Dashboard URL is:

    https://<master node public ip address>

### D. Install the DC/OS command line interface (CLI)

In the DC/OS Dashboard, click on the drop down menu in the upper right side of the dashboard and follow the instructions for installing the DC/OS CLI binary for your OS.

Then run the cluster setup command:

    $ dcos cluster setup https://<master node public ip address>

NOTE: Make sure you use an HTTPS URL in the cluster setup command and not an HTTP URL.

Once the DC/OS CLI is installed, install some sub-commands. This is optional if you run the scripts/prep-cluster.sh script.

    $ dcos package install --cli spark --yes

    $ dcos package install --cli kafka --yes

    $ dcos package install --cli kubernetes --yes

    $ dcos package install dcos-enterprise-cli --yes

### E. Prep the Cluster

To support launching Kubernetes clusters with DC/OS service accounts and SSL certificates, run the prep script that creates the base service account users and their signed certificates using the DC/OS certificate authority (CA). This script also launches four example MKE kubernetes clusters (with their api-server proxies) as well as the Spark dispatcher and a Kafka service.

    $ scripts/prep-cluster.sh

This script will do the following:

- Create DC/OS service account users for k8s-c1 through k8s-5 along with thier DC/OS permissions.
- Create DC/OS secrets with SSL certificates for the above users to be used for enabling TLS.
- Launch the MKE Kubernetes control plane manager (catalog package: Kubernetes).
- Launch four example MKE Kubernetes Clusters (catalog package: Kubernetes Cluster). These clusters will have varying Kubernetes version numbers and will be spread across three availability zones to demonstration high density kubernetes and zone awareness.
- Call the scripts/start-proxies.sh script to launch two HAProxy services to proxy the Kubernetes API Server objects for two of the MKE Kubernetes clusters (k8s-c1 and k8s-c2).
- Call the scripts/setup-kubectl.sh script to setup the Kubernetes cli (kubectl) for two of the MKE Kubernetes clusters (k8s-c1 and k8s-c2) and launch a Chrome browser session for the Kubernetes Dashboard for the k8s-c1 cluster.
- Call the scripts/start-sockshop-pods.sh script to start the Sock Shop microservices demo into pods in the k8s-c1 cluster and to launch a Chrome browser session for the Sock Shop shopping cart web page.

### F. Get the public IP addresses of the DC/OS public agent nodes. 

As part of the demo, you will need to access the public MKE Kubernetes nodes running on the public DC/OS agent nodes. Use the following command to get the public IP address of those DC/OS public agent nodes.

    $ scripts/get-dcos-public-agent-ip.sh 2

NOTE: This is done for you at the end of the prep-cluster.sh script, so you can see the public ip address at the end of the output.

## 2. Demo

### A. DC/OS Overview

Before starting the demo, discuss with the audience what you are going to demonstrate in the next few minutes.

[SHOW]

Show this presentation slide to aid in the overvew discussion.

![DC/OS Overview](/resources/images/Mesosphere-DCOS-Overview.jpg?raw=true)

[SAY]

Hello and welcome to Mesosphere's DC/OS demonstration.  DC/OS, or the Data Center Operating System, is Mesosphere's multi-cloud automation platform. 

With DC/OS you can run cloud native applications at scale using the opensource Kubernetes engine. 

You can run highly distributed GPU enabled data science applications in production and not just on data scientists' laptops, while incorporating machine learning and data science environments such as Spark, BeakerX, Dask, Tensorflow, PyTorch and others. 

DC/OS can also run legacy applications including C, C++, Ruby-on-rails, Python and Java applications and run them along side your new generation of cloud native applications. 

DC/OS exposes an enterprise catalog of pre-built software packages that promotes a self-service oriented deployment environment for developers and application administrators while enforcing central IT controls. 

Data services automation is achieved through a facility we call application-aware scheduling. If you want to run data services such as Elasticsearch, MongoDB, Cassandra, Kafka, HDFS and others, Mesosphere's application-aware schedulers can launch all the tasks that make up a horizontally scaled, highly available data service across data center racks, or cloud-vendor availability zones in a highly orchestrated fashion. DC/OS even supports on-cluster and off-cluster persistant storage volumes for use by data services.

By providing a unified multi-cloud operational environment, DC/OS helps you avoid cloud vendor lock-in. So, if you've been spending months deploying and running dozens or hundreds of applications in one cloud vendor environment and you want to switch over to a second cloud vendor or run on multiple cloud vendors simultaneously, DC/OS allows you to do that without having to re-tool and through away all the automated processes that you used in the initial cloud environment.  In addition to public cloud environments, DC/OS can also run your workloads in your data center without the need for OpenStack, VMWare or other hypervisor technology. 

DC/OS encorporates enterprise security and multi-tenancy features so that you can have multiple teams sharing the same deployment environment as they run their required technology stacks and purpose-built applications - sharing resources such as CPU, Memory and Disk but keeping applications isolated.

DC/OS supports edge computing for IOT applications such as smart cities, connected cars, manufacturing, and other applications that require running some processes outside of the main data center, but DC/OS also supports running applications in on-prem computing resources as well as on public cloud vendor resources including Amazon AWS, Microsoft Azure, and Google Cloud Platform.

This domonstration will illustrate some of the capabilites around cloud-native application deployments, data science applications, legacy application deployments and the enterprise catalog, that launches software package using an application-aware scheduler facility. 

Lets begin.

### B. DC/OS Cluster Overview

[SHOW]

Show the main DC/OS Dashboard Login page. 

![DC/OS Overview](/resources/images/Mesosphere-DCOS-Dashboard-Login.jpg?raw=true)

[SAY]

Before I can access any of the DC/OS Dashboard pages, I must sign in. DC/OS supports integration with LDAP and Active Directory environments as well as with single-signon technologies like SAML 2.0 and OAuth 2.0 via OpenID Connect. 

Here I will login with a local user called admin1.

[SHOW]

Show the main DC/OS Dashboard page.

![DC/OS Overview](/resources/images/Mesosphere-DCOS-Dashboard.jpg?raw=true)

[SAY]

On this main dashboard page, you can see that DC/OS is tracking the availability of pooled resources including CPUs, GPUs, Memory and Disk.  DC/OS can allocate resources dynamically to services that are launched from the Catalog or the Services panel.

[SHOW]

Click on the Nodes menu link on the left pane to show the Nodes list.

![DC/OS Overview](/resources/images/Mesosphere-DCOS-Dashboard-Nodes.jpg?raw=true)

[SAY]

On the Nodes page, you can see the servers or cloud instances that are being managed by DC/OS. Notice that DC/OS is region and zone aware? It shows that I have some cloud instances in availability zones 1a, 1b and 1c. If I was managing on-prem servers, these could be physical racks instead of availability zones. DC/OS can launch workloads with "placement constraints" to spread tasks across these fault zones like racks, data centers or cloud vendor availability zones. 

Note that DC/OS is monitoring the health of these worker nodes so that if one of them goes offline, any workloads that were running on the failed server can be re-launched on the remaining healthy servers. As you may know this happens often in AWS, Azure and other cloud environments where cloud instances can be rebooted without notice.

[SHOW]

Click on the Components menu link on the left pane to show the health status of the DC/OS Components.

![DC/OS Overview](/resources/images/Mesosphere-DCOS-Dashboard-Components.jpg?raw=true)

[SAY]

DC/OS deploys all the ecosystem components that are used to manage the cluster and it monitors the health of these system components. This console shows the health of each component, but DC/OS can also send log messages and health status information to your favorite log management system such as Splunk, Data Dog, ELK, and others.

### C. DC/OS Services - Bin Packing, Fine Grained Resource Sharing & Zone Awareness

[SHOW]

Click on the Services menu link on the left pane to show the services that are presently running on the DC/OS cluster.

![DC/OS Overview](/resources/images/Mesosphere-DCOS-Dashboard-Services.jpg?raw=true)

[SAY]

Lets view some of the workloads that are already running on this DC/OS cluster. This Services page shows that there are 4 Kubernetes clusters running, one Kafka broker environment, a Spark dispatcher and a load balancer (which we will use later). 

Note that we have several different versions of Kubernetes running at the same time - a 1.12.5 version, two 1.13.5 versions and a 1.14.1 version. This can be useful for application development teams that may have different requirements based on the libraries they are using and the version of Kubernetes that their team is testing at. This same capabililty is available for other services too, like Kafka, Cassandra, Spark and more. And DC/OS makes it easy to upgrade these older versions of the packages, which we will demonstrate in a few minutes.

[SHOW]

Click on the Nodes menu link on the left pane to show the DC/OS agents running workloads. Click on the "circle" icon in the upper right corner to display the node CPU allocation page. Then click on one of the servers that is about 90% allocated.

![DC/OS Overview](/resources/images/Mesosphere-DCOS-Dashboard-Services-On-Nodes.jpg?raw=true)

[SAY]

I want to mention here, that we didn't have to stage and configure seperate servers or cloud instances for each Kubernetes cluster, Kafka broker or Spark environment. Instead, we let DC/OS use its bin packing capabilities to share the resources on the worker nodes in a fine grained manner.  When I click on one of these servers, you can see there are tasks from different services running on the same server. Here are tasks from two different Kubernetes clusters (we call that high density Kubernetes) and a Spark dispatcher task.

This is very different than the way cloud vendors allocate resources. If I was running Elastic Map Reduce or EMR on an AWS environment and then wanted to desploy an Elastic Kubernetes Service, AWS would not check to see if I had any CPU, Memory and Disk available on my EMR cluster and then use it for the EKS cluster. It would simply spin up more cloud instances to run EKS and charge me more for it, even though I may have had resources available on my existing cloud instances. It is obvious that with bin packing, DC/OS can save me a ton of money by running more things on fewer cloud instances than the cloud vendors would ever allow. And this same concept works on-prem too. 

### D. DC/OS Package Catalog

[SHOW]

Click on the Catalog menu link on the left pane to show the DC/OS Package Catalog.

![DC/OS Overview](/resources/images/Mesosphere-DCOS-Dashboard-Catalog.jpg?raw=true)

[SAY]

The DC/OS Package Catalog provides certified and community supported pre-built software packages that can easily be deployed to a on-prem or cloud-based cluster. Certified packages are supported by Mesosphere and our partners such as Datastax or Cassandra, Confluent for Kafka, Percona for MongoDB and Lightbend for Spark.

[SHOW]

In the Catalog search box, type in "sql" and press the search button to show the packages that are database oriented. Within the search results, scroll down the list.

![DC/OS Overview](/resources/images/Mesosphere-DCOS-Dashboard-Catalog-SQL.jpg?raw=true)

[SAY]

There are over 100 packages in the Catalog that can easily be deployed, here are some example packages that are database oriented. See how memsql, Postgres, MySQL, CockroachDB, MongoDB and other database packages are available for installing?

[SHOW]

In the Catalog search box, type in "monitor" and press the search button to show the packages that are monitoring oriented. Within the search results, scroll down the list.

![DC/OS Overview](/resources/images/Mesosphere-DCOS-Dashboard-Catalog-Monitor.jpg?raw=true)

[SAY]

Here are some more example packages that are monitoring oriented. See how Sysdig, Weavescope, dynatrace, datadog, Instana and other monitoring  packages are available for installing? Also, see this package called DC/OS Monitoring? Well that is a new package we are in the process of certifying and supporting that deploys Prometheus and Grafana as an easy way to capture and present log data and metrics.

[SHOW]

Click on the Settings->Package Repositories menu link on the left panel to display the package repositories list. Then click on the plus sign (+) in the upper right corner to add a new repository.

![DC/OS Overview](/resources/images/Mesosphere-DCOS-Dashboard-Catalog-Add-Repository.jpg?raw=true)

[SAY]

By the way, while Mesosphere maintains this default package Catalog, you are not limited to installing only these software packages. Customers can add their own packages to the Catalog using the DC/OS Universe github repo tools to create new Catalog packages. In this way, customers can add their own package Catalog repos behind their firewall for private use.


### E. Demonstrate starting mixed workloads including:

- Jenkins
- Cassandra

[SHOW]

Click on the Catalog menu link and then click on the Jenkins package. Click on the dropdown list of versions for Jenkins and then click on the Review and Run button.

![DC/OS Overview](/resources/images/Mesosphere-DCOS-Dashboard-Jenkins.jpg?raw=true)

[SAY]

Lets see a couple of examples of running Catalog packages. 

First, I am selecting the Jenkins package, which many of our customers use to support their CI/CD pipelines. As you can see, I have the option of selecting from serveral versions of Jenkins, but I will use the latest. 

After I click on the Review and Run button, I am able to specify many different options for configuring Jenkins. If I am going to run one Jenkins service for multiple dev teams, I may keep it generic, but I do have the option of creating multiple Jenkins instances, one for each dev team and to do that I can specify a service group name like this: "/webapps/jenkins". Later, I can add access controls on users and groups that can be granted access to this webapps group. I can also specify storage options, including using persistent storage volumes. And while this main Jenkins task will run on a server, it can spawn many build threads that can run on all the servers in the cluster, which allows it to scale better than a static build server would allow.

Lets go ahead and click the Review and Run button to start this Jenkins service.  You can see that DC/OS is allocating CPU and Memory to the service and starting it on one of the worker nodes.

[SHOW]

Click on the Catalog menu link and then click on the Cassandra package. Click on the Review and Run button.

![DC/OS Overview](/resources/images/Mesosphere-DCOS-Dashboard-Cassandra.jpg?raw=true)

[SAY]

Going back to the Catalog, lets run a Cassandra ring. Cassandra is a very scaleable data store that is designed around a peer-to-peer model instead of a master/worker node model. Cassandra replicates its data across multiple nodes, providing high availability and better performance.

With Cassandra, I can specify a service group, just like I did with the Jenkins service, so I will enter /webapps/cassandra as the service name. As I scroll down, you can see that I have the option to select the cloud vendor's region for placement of this Cassandra service. I may opt to run one Cassandra service in two different regions, to provide disaster recovery capabilities. Also, when I click on Nodes, I have the option of specifying the number of availability zones to run my Cassandra nodes accross. I will select 3 zones, so that if one zone were to become unavailable, I know my Cassandra data would still be replicated on the other two zones.

I am going to click on the Review and Run button to deply this Cassandra service. Like with other services I start, DC/OS first deploys the application aware scheduler that then launches the proper tasks needed to make up a healthy Cassandra ring. Waiting a few seconds will show the first Cassandra node being started, later, the second and third will start.

One final comment I want to add before we move on... All the actions I am showing you using the web based console can also be performed using the DC/OS command line interface and the DC/OS REST API. So for your power-users that would rather script these processes, they will be able to do that using shell scripts, ansible scripts and the like.


### F. Supporting Cloud Native Applications with  Multiple Kubernets Clusters

TBD

Discuss how Enterprise DC/OS combined with the Mesosphere Kubernetes Engine or MKE supports "high density" kubernetes clusters that enable launching different versions of Kubernetes clusters to support different development teams. And how DC/OS uses an un-forked version of the opensource version of Kubernetes and the kubectl package. And how DC/OS allows kubernetes control plan components and worker node components to be spread across cloud availability zones for HA reasons. 

Use the Dashboard's Services panel to show how the example MKE clusters are running tasks that are spread across availability zones and how (with high density Kubernetes support) DC/OS is running tasks from multiple Kubernetes clusters on the SAME servers or cloud instances!

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

Talk about how MKE can implement Kubernetes RBAC with the click of a checkbox and how it can enable HA too (in fact k8s-c1 cluster is deployed in HA mode).

### E. Demonstrate kubctl commands

The prep-cluser.sh script called the setup-kubectl.sh script which setup the kubectl command pointing to the k8s-c1 cluster. Additionally the start-sockshop-pods.sh script was called to load the sockshop microservices example application running with nodeport functionality in Kubernetes pods. Point your web browser to one of the DC/OS public agent nodes running and point to the Sockshop shopping cart example app:

    http://<public agent public ip address>:30001

Talk about how the sock shop application was deployed as pods onto the Kubernetes cluster, including the user interface components, the business rules and the backend messaging and database components (RabbitMQ and MongoDB). Show the Sock Shop Pods running by selectin the "sockshop" namespace in the Kubernetes Dashboard, or by running the kubectl command:

     $ kubectl -n sock-shop get pods

Show how you can use the kubectl command to scale the sock shop's user interface microservices by running the commands:

     $ kubectl -n sock-shop get deployment front-end

     $ kubectl -n sock-shop scale deployment front-end --replicas=3

     $ kubectl -n sock-shop get deployment front-end

Or, you can do the same thing in the Kubernetes Dashbaord, but clicking on the "Deployments" panel, then selecting the "..." dropdown menu option for "Scale".

You can also demonstrate interacting with the Kubernetes cluster using other kubectl commands. Some example kubectl commands can be found in:

    examples/kubectl-examples.txt

If you want to demonstrate installing Helm and a Heml Chart, you can experiment with the commands found in:

    examples/helm-examples.txt

### F. Upgrading a Kubernetes cluster

Discuss how Enterprise DC/OS automates the process of upgrading, in a rolling fashion, the upgrading of Kubernetes clusters without disrupting the pods running on the Kubernetes cluster. Also, discuss how DC/OS has a built-in CLI command that can backup the Kubernetes cluster meta-data (from the etcd daemons) so that a Kubernetes cluster's state can be restored from a backup in the case of a failure or building a new Kubernetes cluster.

Use the DC/OS CLI to upgrade the second Kubernetes cluster from 1.13.5 to the latest release (1.14.1 as of this time). The upgrade commands can be found in an example file at:

    examples/kubernetes-upgrade-example.txt

Use the following commands to upgrade the second Kubernetes cluster:

    $ dcos package install kubernetes --cli --package-version=2.3.0-1.14.1 --yes

    $ dcos kubernetes cluster update  --cluster-name=k8s-c1 --package-version=2.3.0-1.14.1 --yes

Go to the DC/OS Dashboard and display the "Tasks" and "Plans" page for the k8s-c1 kubernetes cluster and show the progression of the upgrade. Talk about how the DC/OS MKE control plan is doing an orderly upgrade of the Kubernetes cluster by doing each master node task one at a time (etcd-0, etcd-1, etcd-2, kube-control-plane-0, kube-control-plane-1, and kube-control-plane-2). Mention how all this is done without requiring the Kubernetes cluster to experience any downtime. Also, if the customer had modified the SSL keys in the service accounts and secrets, those new keys would be installed for each restarted task as well.

### G. Analytics and Machine Learning with Jupyter

TBD

Launching Jupyter Catalog package:  

     Public Agent hostname: <Public Agent Public IP Address>

Access the Jupyter Web console, after it starts:

     http://<Public Agent Public IP Address>:10108/jupyterlab-notebook  (password: jupyter)

Click on teh 2nd Orange Apache Toree - Scala icon, to open that notebook.

Then, copy and paste the following into the notebook.

     val NUM_SAMPLES = 10000000
     
     val count2 = spark.sparkContext.parallelize(1 to NUM_SAMPLES).map{i =>
       val x = Math.random()
       val y = Math.random()
       if (x*x + y*y < 1) 1 else 0
     }.reduce(_ + _)
     
     println("Pi is roughly " + 4.0 * count2 / NUM_SAMPLES)

Then press the run icon to run the Scala program.

### H. Legacy Application Support

TBD

Run the example Tomcat application.

Docker Image to use:

     tomcat:latest

Artifact Location:

     https://tomcat.apache.org/tomcat-7.0-doc/appdev/sample/sample.war

Command to use:

     mv /mnt/mesos/sandbox/sample.war /usr/local/tomcat/webapps/sample.war && /usr/local/tomcat/bin/catalina.sh run

Access the Tomcat default console via the Marathon-LB instance (named loadbalancer):

     https://<Public Agent Node Public IP Address>:10005

Access the Marathon-LB (loadbalancer) stats console at:

     https://<Public Agent Node Public IP Address>:9090/haproxy?stats

### I. Demonstrate the Enterprise DC/OS features

TBD

While the new Kubernets clusters is launching, use the DC/OS Dashboard to show how DC/OS:

- Integrates with LDAP/AD servers
- Integrates with SAML 2.0 and OAuth2 authention servers
- Supports encrypted secrets
- Provides multi-tenancy at the administrator level by enforcing access control list permissions

Create two user groups (webapps, and mobileapps), then create a user and add it to the mobileapps group.

Add ACL rules to the mobileapps group by copying the contents of:

    examples/acl-examples.txt

into the Permissions panel for the webapps group.

Then log off as the super user and log in as the user you created. Show how many of the left side menu options are missing and try to start a MySQL package in the application group:

    /mobileapps/mysql

Show how DC/OS does not allow the user to start MySQL into that application group. Then change it to the group:

    /webapps/mysql

And show how DC/OS allows that and by looking at the Services panel, how the MySQL package is "deploying".


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


