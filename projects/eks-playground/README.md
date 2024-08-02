# EKS Playground

## AWS Credentials

If an AWS SSO profile isn't configured on your machine:

```
aws configure sso
```

Then:

```
aws login sso
```

## VPC

Note that the VPC was created via CloudFormation:

```
aws cloudformation create-stack \
  --region us-east-2 \
  --stack-name eks-vpc-stack \
  --template-url https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml
```

## K8s

After deploying the cluster, do the following to configure `kubectl`:

```
aws eks update-kubeconfig --region us-east-2 --name playground
```

Connecting to a node from the sample app:

```
kubectl exec -it <pod name> -n eks-sample-app -- /bin/bash
```
