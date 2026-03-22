# ============================================================================
# ArgoCD — GitOps Controller on EKS cho TRAVEL-WEB
# ============================================================================
# Architecture decisions:
#   1. Dedicated "argocd" namespace — full isolation from workloads.
#   2. ClusterIP only — no public LoadBalancer. Access via:
#        kubectl port-forward svc/argocd-server -n argocd 8080:443
#   3. Pull-based GitOps — ArgoCD polls the Git manifest repo and
#      reconciles the desired state into the target namespace ("app").
#   4. Strict depends_on — Helm release waits for EKS + Node Groups.
# ============================================================================

# ---------------------------------------------------------------------------
# 1. Namespaces
# ---------------------------------------------------------------------------
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      purpose                        = "gitops"
    }
  }

  depends_on = [module.eks]
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.argocd_target_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "argocd"
      purpose                        = "workloads"
    }
  }

  depends_on = [module.eks]
}

# ---------------------------------------------------------------------------
# 2. Helm Release — ArgoCD
# ---------------------------------------------------------------------------
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Chờ mọi resource Helm tạo ra thực sự Ready trước khi Terraform đánh dấu xong
  wait    = true
  timeout = 600 # 10 phút — lần đầu pull images có thể lâu

  # ---- ArgoCD Server: ClusterIP, không lộ ra Internet ----
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # Tắt TLS trên ArgoCD server (sẽ port-forward plaintext qua kubectl)
  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  # ---- HA tuỳ chọn: tắt ở dev, bật ở prod ----
  set {
    name  = "redis-ha.enabled"
    value = "false"
  }

  set {
    name  = "controller.replicas"
    value = "1"
  }

  set {
    name  = "server.replicas"
    value = "1"
  }

  set {
    name  = "repoServer.replicas"
    value = "1"
  }

  set {
    name  = "applicationSet.replicas"
    value = "1"
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.argocd,
  ]
}

# ---------------------------------------------------------------------------
# 3. ArgoCD Application — bootstrap GitOps repo (pull-based)
# ---------------------------------------------------------------------------
# Dùng kubernetes_manifest để tạo ArgoCD Application CRD.
# Resource này chỉ apply sau khi Helm release argocd đã Ready
# (CRD "applications.argoproj.io" mới tồn tại lúc đó).
# ---------------------------------------------------------------------------
resource "kubernetes_manifest" "argocd_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.argocd_app_name
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      project = "default"

      source = {
        repoURL        = var.argocd_repo_url
        targetRevision = var.argocd_repo_revision
        path           = var.argocd_repo_path
      }

      destination = {
        server    = "https://kubernetes.default.svc" # in-cluster
        namespace = var.argocd_target_namespace
      }

      syncPolicy = {
        automated = {
          prune    = true  # Xoá resource K8s khi bị xoá khỏi Git
          selfHeal = true  # Tự rollback nếu ai sửa tay trên cluster
        }
        syncOptions = [
          "CreateNamespace=true",
          "PruneLast=true",
        ]
        retry = {
          limit = 3
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "3m"
          }
        }
      }
    }
  }

  depends_on = [helm_release.argocd]
}
