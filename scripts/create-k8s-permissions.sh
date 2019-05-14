#!/bin/bash
#
# SCRIPT: k8s-permissions.sh
#
# USAGE:
#    dcos package install --yes dcos-enterprise-cli
#    ./permissions.sh <new-service-account-userid>
#

if [ "$1" == "" ]
then
    echo
    echo " ERROR: No new service account user id was specified. " 
    echo
    echo "        USAGE: k8s-permissions.sh <new service account user id>"
    echo
    echo " Exiting."
    exit -1
else
    user_id=$1
fi

rm -f /tmp/private-key.pem /tmp/public-key.pem > /dev/null 2>&1

# check if service account user already exists
dcos security org service-accounts show ${user_id} > /dev/null 2>&1
if [ "$?" == 0 ]
then
    echo " Service account user: ${user_id} already exists. Skipping"
else
    echo " Creating service account user id: $user_id"

    dcos security org service-accounts keypair /tmp/private-key.pem /tmp/public-key.pem
    dcos security org service-accounts create -p /tmp/public-key.pem -d 'Kubernetes service account' ${user_id}
    dcos security secrets create-sa-secret /tmp/private-key.pem ${user_id} ${user_id}/sa
    dcos security org users grant ${user_id} dcos:mesos:master:framework:role:${user_id}-role create
    dcos security org users grant ${user_id} dcos:mesos:master:task:user:root create
    dcos security org users grant ${user_id} dcos:mesos:master:task:user:nobody create
    dcos security org users grant ${user_id} dcos:mesos:agent:task:user:root create
    dcos security org users grant ${user_id} dcos:mesos:master:reservation:role:${user_id}-role create
    dcos security org users grant ${user_id} dcos:mesos:master:reservation:principal:${user_id} delete
    dcos security org users grant ${user_id} dcos:mesos:master:volume:role:${user_id}-role create
    dcos security org users grant ${user_id} dcos:mesos:master:volume:principal:${user_id} delete
    dcos security org users grant ${user_id} dcos:secrets:default:/${user_id}/* full
    dcos security org users grant ${user_id} dcos:secrets:list:default:/${user_id} read
    dcos security org users grant ${user_id} dcos:adminrouter:ops:ca:rw full
    dcos security org users grant ${user_id} dcos:adminrouter:ops:ca:ro full
    dcos security org users grant ${user_id} dcos:mesos:master:framework:role:slave_public/${user_id}-role create
    dcos security org users grant ${user_id} dcos:mesos:master:framework:role:slave_public/${user_id}-role read
    dcos security org users grant ${user_id} dcos:mesos:master:reservation:role:slave_public/${user_id}-role create
    dcos security org users grant ${user_id} dcos:mesos:master:volume:role:slave_public/${user_id}-role create
    dcos security org users grant ${user_id} dcos:mesos:master:framework:role:slave_public read
    dcos security org users grant ${user_id} dcos:mesos:agent:framework:role:slave_public read
    
    rm -f /tmp/private-key.pem /tmp/public-key.pem > /dev/null 2>&1
fi

# end of script
