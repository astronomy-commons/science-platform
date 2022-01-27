#!/bin/bash

# Switch to deployment directory and load the config
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$(dirname $DIR)"
. scripts/common.sh

test_dependency helm

# Create a new chart archive versioned
# Chart version depends on the value in Chart.yaml
# archives added to docs/ and the index.yaml there
# determine what versions of this Helm chart are publicly available
helm dependency update chart/
helm package chart/
mv public-hub*.tgz docs/.
helm repo index docs/.