resource "aws_iam_role" "node" {
    name = "${var.prefix}-${var.cluster_name}-role-node"
    assume_role_policy = <<POLICY
{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
POLICY
}

// Allow worker to run in cluster
resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
    role = aws_iam_role.node.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

// CNI allow communication between nodes
resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
    role = aws_iam_role.node.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

// Container registry access is mandatory to download docker image
resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
    role = aws_iam_role.node.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "nodes" {
    count = 2
    cluster_name = aws_eks_cluster.my-cluster.name
    node_group_name = "node-${count.index + 1}"
    node_role_arn = aws_iam_role.node.arn
    subnet_ids = aws_subnet.subnets[*].id
    instance_types = ["t3.micro"]
    
    scaling_config {
        desired_size = var.desired_size
        max_size = var.max_size
        min_size = var.min_size
    }

    depends_on = [
        aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
        aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
        aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly
    ]
}

