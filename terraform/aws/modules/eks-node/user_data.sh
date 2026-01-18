#!/bin/bash
set -o xtrace

# Bootstrap script for EKS worker nodes
/etc/eks/bootstrap.sh ${cluster_name} \
  --b64-cluster-ca '${cluster_ca}' \
  --apiserver-endpoint '${cluster_endpoint}' \
  --container-runtime containerd \
  --kubelet-extra-args '--max-pods=110 --cluster-dns=10.100.0.10'

/opt/aws/bin/cfn-signal --exit-code $? \
  --stack EKS-Stack \
  --resource NodeGroup \
  --region $AWS_DEFAULT_REGION
