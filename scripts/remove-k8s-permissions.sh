#!/bin/bash
#
# SCRIPT: remove-k8s-permissions.sh
#
# USAGE:
#    dcos package install --yes dcos-enterprise-cli
#    ./remove-k8s-permissions.sh <service-account-userid>
#

if [ "$1" == "" ]
then
    echo
    echo " ERROR: No new service account user id was specified. " 
    echo
    echo "        USAGE: remove-k8s-permissions.sh <service account user id>"
    echo
    echo " Exiting."
    exit -1
else
    user_id=$1
fi

    # get a list of secrets for this service account user (remove the dash char)
    secrets_list=$(dcos security secrets list ${user_id} | sed 's/^-//g')

    chrlen=${#secrets_list}
    if [ "$chrlen" != "0" ]
    then
        echo
        echo " Removing secrets for service account user: ${user_id}."
        echo
        for secret_name in `echo $secrets_list`
        do 
            #echo " Removing secret: $secret_name"
            dcos security secrets delete ${user_id}/${secret_name}
        done
    else
        echo
        echo " No secrets found for service account user: ${user_id}. Skipping"
        echo
    fi

    # check if service account user exists
    dcos security org service-accounts show ${user_id} > /dev/null 2>&1
    if [ "$?" != 0 ]
    then
        echo " No Service account user ${user_id} found. Skipping"
    else

        # delete the service account user
        echo
        echo " Removing service account for user ${user_id}"
        echo
        dcos security org service-accounts delete ${user_id}
    fi

# end of script
