#!/bin/bash
#
# SCRIPT: launch-cluster.sh
#
# DESC: This script uses the Mesosphere Universal Installer (terraform based) to launch
#       a DC/OS cluster in AWS.
#
# AUTHOR: Greg Palmer
#

# Check if the maws utility is installed
maws_cmd=$(which maws)
if [ "$maws_cmd" == "" ]
then
    echo
    echo " Error: Command \"maws\" not found. Please install the maws utility"
    echo "        and try again."
    echo
    echo " See https://github.com/mesosphere/maws"
    echo "     or"
    echo " Try: $ brew install maws"
    echo 
    exit 1
fi

# Check if the AWS CLI utility is installed
aws_cmd=$(which aws)
if [ "$aws_cmd" == "" ]
then
    echo
    echo " Error: The AWS CLI Command \"aws\" not found. Please install the AWS CLI utility"
    echo "        and try again."
    echo
    echo " Try: $ brew install awscli "
    echo
    exit 1
fi

# Check if the terraform utility is installed
tf_cmd=$(which terraform)
if [ "$tf_cmd" == "" ]
then
    echo
    echo " Error: The terraform CLI Command \"terraform\" not found. Please install the terraform CLI utility"
    echo "        and try again."
    echo
    echo " Try: $ brew install terraform "
    echo
    exit 1
fi

# Check if the cluster directory exists
if [ ! -d "./cluster" ]
then
    echo
    echo " Error: directory \"./cluster\" not found. Please run this script"
    echo "        from the dcos-demo-1.13 directory."
    echo 
    exit 1
fi

# change directory to the cluster directory
orig_dir=$(pwd)
cd cluster

eval $(maws login 110465657741_Mesosphere-PowerUser)

if [ ! -f ~/.ssh/id_rsa-terraform ]
then
    echo
    echo " SSL key \"~/.ssh/id_rsa-terraform\" not found, generating one."
    echo

    # check if ssh-keygen utility is installed
    keygen_cmd=$(which ssh-keygen)
    if [ "$keygen_cmd" == "" ]
    then
        echo " Error: SSH Keygen command \"ssh-keygen\" not found. Please install the SSH Keygen"
        echo "        utility and try again."
        echo
    fi

    # create the ~/.ssh directory if not already created
    if [ ! -d ~/.ssh ]
    then
        mkdir ~/.ssh
    fi

    # generate the ssh key
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa-terraform
    chmod 400 ~/.ssh/id_rsa-terraform && chmod 400 ~/.ssh/id_rsa-terraform.pub
fi

# add the ssh key to the cache
ssh-add ~/.ssh/id_rsa-terraform

sleep 2

export AWS_DEFAULT_REGION="us-east-1"

# Create the terraform plan and apply it
terraform init -upgrade=true && terraform plan -out plan.out && terraform apply -auto-approve plan.out

cd $orig_dir

echo
echo
echo " To destroy the cluster, use the following command:"
echo
echo "      scripts/destroy-cluster.sh"
echo
echo " OR run "
echo
echo "      $ eval \$(maws login 110465657741_Mesosphere-PowerUser) && terraform destroy"
echo


# end of script
