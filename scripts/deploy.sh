#!/bin/bash

# Switch to deployment directory and load the config
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$(dirname $DIR)"
. scripts/common.sh

test_dependency kubectl
test_dependency helm

test_var NAMESPACE
test_var RELEASE

kubectl get namespace $NAMESPACE || kubectl create namespace $NAMESPACE
# values=$(for file in $(ls *.yaml); do echo --values $file; done)
helm upgrade --install $RELEASE \
	--namespace $NAMESPACE \
	./chart \
	--values values-eks.yaml \
	--values values-customize.yaml