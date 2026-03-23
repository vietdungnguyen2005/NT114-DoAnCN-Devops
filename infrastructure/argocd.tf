# ============================================================================
# ArgoCD — GitOps Controller on EKS cho TRAVEL-WEB
# ============================================================================
# Architecture decisions:
#   1. Dedicated "argocd" namespace — full isolation from workloads.
#   2. ClusterIP + Traefik Ingress — exposed via existing NLB.
#      Access via Traefik LoadBalancer URL.
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

  # ---- ArgoCD Server: ClusterIP — exposed via Traefik Ingress ----
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # Tắt TLS nội bộ — Traefik sẽ handle TLS termination
  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  # ArgoCD root path — cho phép chạy ArgoCD UI tại /argocd
  set {
    name  = "configs.params.server\\.rootpath"
    value = "/argocd"
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

# ---------------------------------------------------------------------------
# 4. Ingress — Expose ArgoCD qua Traefik NLB (không cần domain)
# ---------------------------------------------------------------------------
resource "kubernetes_ingress_v1" "argocd" {
  metadata {
    name      = "argocd-external"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
    }
  }

  spec {
    ingress_class_name = "traefik"

    # Rule: /argocd → ArgoCD (app dùng / riêng)
    rule {
      http {
        path {
          path      = "/argocd"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.argocd]
}
