#!/usr/bin/env bash

# Switch to deployment directory and load the config
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd "$(dirname $DIR)"
. scripts/common.sh
pushd "$(dirname $DIR)/cluster"

test_dependency curl
test_dependency wget
test_dependency eksctl
test_dependency kubectl
test_dependency aws
test_dependency python3
if ! python3 -c "import yaml"; then
    echo "install yaml"
    exit -1
fi

mkdir -p load_balancer

REGION="us-west-2"
CLUSTER_NAME="pufsalad"
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"

ACCOUNT_ID=$(aws sts get-caller-identity | jq -r '.Account')
echo "Running with ACCOUNT_ID=${ACCOUNT_ID}"

# https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
oidc_issuer_id=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output json | jq -r 'split("/") | .[-1]')
test_oidc_issuer_associated=$(aws iam list-open-id-connect-providers | jq -r '.OpenIDConnectProviderList | .[].Arn | split("/") | .[-1] ' | grep ${oidc_issuer_id})

if [ ${test_oidc_issuer_associated} ]; then
    echo "OIDC Issuer associated with cluster"
else
    echo "OIDC Issuer needs to be associated with cluster"
    eksctl utils associate-iam-oidc-provider --cluster=${CLUSTER_NAME} --approve
fi

# https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/installation/#add-controller-to-cluster
curl -o load_balancer/iam-policy-${POLICY_NAME}.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.1/docs/install/iam_policy.json

policy_exists=$(aws iam list-policies | jq -r '.Policies | .[].PolicyName ' | grep ${POLICY_NAME})
if [ $policy_exists ]; then
    echo "IAM policy ${POLICY_NAME} exists"
else
    echo "Creating ${POLICY_NAME} IAM policy"
    aws iam create-policy \
        --policy-name ${POLICY_NAME} \
        --policy-document file://load_balancer/iam-policy-${POLICY_NAME}.json
fi

eksctl create iamserviceaccount \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --cluster ${CLUSTER_NAME} \
    --attach-policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME} \
    --override-existing-serviceaccounts \
    --region ${REGION} \
    --approve

# Test if made
role_arn=$(aws cloudformation describe-stacks \
    --stack-name eksctl-${CLUSTER_NAME}-addon-iamserviceaccount-kube-system-aws-load-balancer-controller \
    --query='Stacks[].Outputs[?OutputKey==`Role1`].OutputValue' \
    --output text)
echo "Made role: ${role_arn}"

# Install to cluster
# Install cert-manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.5.3/cert-manager.yaml
# Download spec for load balancer controller
wget -O load_balancer/lb_pre.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.1/v2_4_1_full.yaml 
# replace cluster name
sed -i "s/your-cluster-name/${CLUSTER_NAME}/g" load_balancer/lb_pre.yaml

read -r -d '' script <<'EOF'
import io
import sys
import yaml
write_contents = []
with open("load_balancer/lb_pre.yaml", "r") as f:
    contents = f.read()
    for d in contents.split("---"):
        data = yaml.load(d)
        if data['kind'] == "ServiceAccount":
            print("Removing service account:", data, file=sys.stderr)
        else:
            write_contents.append(d)
print("---".join(write_contents))
EOF

python3 -c "${script}" > load_balancer/lb.yaml
kubectl apply -f load_balancer/lb.yaml

popd
