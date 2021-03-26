
CLUSTER_NAME="pufsalad"
ACCOUNT_ID=$(aws sts get-caller-identity | jq -r '.Account')

eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=cluster-autoscaler \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/<AmazonEKSClusterAutoscalerPolicy> \
  --override-existing-serviceaccounts \
  --approve