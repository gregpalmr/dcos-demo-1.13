#!/bin/bash
#
# SCRIPT: destroy-cluster.sh
#
# DESC: This script uses the Mesosphere Universal Installer (terraform based) to destroy
#       a DC/OS cluster in AWS.
#
# AUTHOR: Greg Palmer
#

# Check if the cluster directory exists
if [ ! -d "./cluster" ]
then
    echo
    echo " Error: directory \"./cluster\" not found. Please run this script"
    echo "        from the dcos-demo-1.13 directory."
    echo
    exit 1
fi

orig_dir=$(pwd)
cd cluster

eval $(maws login 110465657741_Mesosphere-PowerUser)

sleep 2

export AWS_DEFAULT_REGION="us-east-1"

echo
echo " Running command: terraform destroy -auto-approve "
echo

terraform destroy -auto-approve

cd $orig_dir

# end of script
