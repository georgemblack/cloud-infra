resource "aws_eks_cluster" "playground" {
  name     = "playground"
  role_arn = aws_iam_role.control_plane.arn
  version  = "1.30"

  vpc_config {
    subnet_ids = ["subnet-04f66ea02247bc584", "subnet-0f9cbdf368bc6ad90", "subnet-0226e3dc3e316e98f", "subnet-03be606c48b2b7e13"]
  }
}

output "endpoint" {
  value = aws_eks_cluster.playground.endpoint
}

resource "aws_eks_fargate_profile" "default" {
  cluster_name           = aws_eks_cluster.playground.name
  fargate_profile_name   = "default"
  pod_execution_role_arn = aws_iam_role.pod_execution.arn
  subnet_ids             = ["subnet-0f9cbdf368bc6ad90", "subnet-03be606c48b2b7e13"]

  selector {
    namespace = "george-fg"
  }
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.playground.name
  addon_name   = "eks-pod-identity-agent"
}

# resource "aws_eks_node_group" "sample_group" {
#   cluster_name    = aws_eks_cluster.playground.name
#   node_group_name = "georgegroup"
#   node_role_arn   = aws_iam_role.managed_node_group.arn
#   subnet_ids      = ["subnet-0f9cbdf368bc6ad90", "subnet-03be606c48b2b7e13"]

#   scaling_config {
#     desired_size = 1
#     max_size     = 2
#     min_size     = 1
#   }

#   labels = {
#     "nodetype" = "georgegroup"
#   }

#   # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
#   # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
#   depends_on = [
#     aws_iam_role_policy_attachment.managed_node_group-AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.managed_node_group-AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.managed_node_group-AmazonEC2ContainerRegistryReadOnly,
#   ]
# }

