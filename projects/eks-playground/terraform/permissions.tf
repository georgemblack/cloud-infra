# resource "aws_eks_pod_identity_association" "george_fg" {
#   cluster_name    = aws_eks_cluster.playground.name
#   namespace       = "george-fg"
#   service_account = "default"
#   role_arn        = aws_iam_role.george_fg.arn
# }
