# Cluster creation

Originally run with `eksctl` version `0.35.0`.

Creates an AWS managed Kubernetes cluster through the AWS EKS service.

## EBS CSI Driver

You can install the AWS EBS CSI driver (to enable `gp3` volume support) with the included script `./aws-ebs-csi-driver.sh`. See the documentation here: [https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html)

## AWS Load Balancer Controller

You can install the AWS Load Balancer Controller (to enable Network Load Balancer support) with the included script `./aws-load-balancer-controller.sh`. See the documentation here: [https://kubernetes-sigs.github.io/aws-load-balancer-controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller)