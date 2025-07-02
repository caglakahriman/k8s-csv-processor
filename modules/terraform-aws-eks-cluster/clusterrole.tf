resource "kubernetes_cluster_role" "readonly" {
  count = var.create_readonly_clusterrole ? 1 : 0
  metadata {
    name = "cluster:read-only"
  }

  rule {
    api_groups = [""] # this is the root-api-group
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["*"] # all other api-groups
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [ aws_eks_cluster.this ]
}

resource "kubernetes_cluster_role_binding" "readonly" {
  count = var.create_readonly_clusterrole ? 1 : 0
  metadata {
    name = "cluster:read-only"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster:read-only"
  }

  subject {
    kind      = "Group"
    name      = "cluster:read-only-group"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "User"
    name      = "cluster:read-only-user"
    api_group = "rbac.authorization.k8s.io"
  }
}

