#!/bin/bash

# Switch to deployment directory and load the config
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$(dirname $DIR)"
. scripts/common.sh

test_dependency helm

helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm upgrade --install autoscaler \
  --namespace kube-system \
  autoscaler/cluster-autoscaler \
  --version 9.11.0 \
  --values values-autoscaler.yaml
