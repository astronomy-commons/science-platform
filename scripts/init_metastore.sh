#!/bin/bash

# Switch to deployment directory and load the config
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$(dirname $DIR)"
. scripts/common.sh

test_dependency jq
test_dependency kubectl

test_var NAMESPACE
test_var RELEASE

function init_container_pending() {
    [[ "$(kubectl -n $NAMESPACE get pods -l component=init-metastore --no-headers | awk '{print $3}')" != "Running" ]]
    return $?
}

function mariadb_container_pending() {
    [[ "$(kubectl -n $NAMESPACE get pods $RELEASE-mariadb-0 --no-headers | awk '{print $2" "$3}')" != "1/1 Running" ]]
    return $?
}

function init_deployment_exists() {
    [[ "$(kubectl -n $NAMESPACE get deployment init-metastore -o json)" ]]
    return $?
}

function init_metastore_pods_exist() {
    [[ $(kubectl -n $NAMESPACE get pods -l component=init-metastore -o json | jq -r ".items | length") != "0" ]]
    return $?
}

hdr=
while mariadb_container_pending
do
	if [[ -z $hdr ]]; then
		echo -n "waiting for mariadb pod to start..."
		hdr=1
	else
		echo -n "."
	fi
    sleep 1
done

if init_metastore_pods_exist
then
    kubectl -n $NAMESPACE scale deployments init-metastore --replicas=0
fi

while init_metastore_pods_exist
do
    sleep 1
done

# Scale deployment to one pod
kubectl -n $NAMESPACE scale deployments init-metastore --replicas=1

hdr=
while init_container_pending
do
	if [[ -z $hdr ]]; then
		echo -n "init-metastore pod starting..."
		hdr=1
	else
		echo -n "."
	fi
    sleep 1
done

PYTHON_SCRIPT=$(cat scripts/init_metastore.py)
pod_name=$(kubectl -n $NAMESPACE get pods -l component=init-metastore --output json | jq -r '.items | .[0].metadata.name')
kubectl -n $NAMESPACE exec $pod_name -it -- /usr/local/bin/entrypoint.sh bash -c "python -c '${PYTHON_SCRIPT}'"

kubectl -n $NAMESPACE scale deployments init-metastore --replicas=0
