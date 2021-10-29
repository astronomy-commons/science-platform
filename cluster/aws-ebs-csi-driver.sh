#!/usr/bin/env bash

# Switch to deployment directory and load the config
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd "$(dirname $DIR)"
. scripts/common.sh
pushd "$(dirname $DIR)/cluster"

test_dependency curl
test_dependency eksctl
test_dependency kubectl
test_dependency aws

mkdir -p ebs_driver

GH_TAG="release-1.2"
CLUSTER_NAME="pufsalad"
POLICY_NAME="AmazonEKS_EBS_CSI_Driver_Policy"

ACCOUNT_ID=$(aws sts get-caller-identity | jq -r '.Account')
echo "Running with ACCOUNT_ID=${ACCOUNT_ID}"

curl -o ebs_driver/iam-policy-${POLICY_NAME}.json https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/${GH_TAG}/docs/example-iam-policy.json

# Validate aws install?
policy_exists=$(aws iam list-policies | jq -r '.Policies | .[].PolicyName ' | grep ${POLICY_NAME})
if [ $policy_exists ]; then
    echo "IAM policy ${POLICY_NAME} exists"
else
    echo "Creating ${POLICY_NAME} IAM policy"
    aws iam create-policy \
        --policy-name ${POLICY_NAME} \
        --policy-document file://ebs_driver/iam-policy-${POLICY_NAME}.json
fi

# https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
oidc_issuer_id=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output json | jq -r 'split("/") | .[-1]')
test_oidc_issuer_associated=$(aws iam list-open-id-connect-providers | jq -r '.OpenIDConnectProviderList | .[].Arn | split("/") | .[-1] ' | grep ${oidc_issuer_id})

if [ ${test_oidc_issuer_associated} ]; then
    echo "OIDC Issuer associated with cluster"
else
    echo "OIDC Issuer needs to be associated with cluster"
    eksctl utils associate-iam-oidc-provider --cluster=${CLUSTER_NAME} --approve
fi

eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster ${CLUSTER_NAME} \
    --attach-policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME} \
    --approve \
    --override-existing-serviceaccounts

# Test if made
role_arn=$(aws cloudformation describe-stacks \
    --stack-name eksctl-${CLUSTER_NAME}-addon-iamserviceaccount-kube-system-ebs-csi-controller-sa \
    --query='Stacks[].Outputs[?OutputKey==`Role1`].OutputValue' \
    --output text)
echo "Made role: ${role_arn}"

# Install Driver
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=${GH_TAG}"
