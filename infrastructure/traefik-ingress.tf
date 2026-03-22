# ============================================================================
# Traefik Ingress Controller — Reverse Proxy inside EKS (replaces Nginx)
# ============================================================================
# Architecture flow:
#   Internet → ALB (created by AWS LB Controller via Ingress annotations)
#            → Traefik Ingress Controller (pods)
#            → travel-web-app service (Next.js on port 3000)
#
# Why Traefik over Nginx:
#   - Native Kubernetes integration via CRDs (IngressRoute, Middleware)
#   - Built-in canary/weighted routing for progressive deployments
#   - Built-in dashboard for monitoring routes and services
#   - Automatic Let's Encrypt certificate management
#   - Native support for circuit breakers and rate limiting
# ============================================================================

resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  depends_on = [module.eks]
}

resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = var.traefik_chart_version
  namespace  = kubernetes_namespace.traefik.metadata[0].name

  wait    = true
  timeout = 600

  # --- Service Type: LoadBalancer provisioned by AWS LB Controller ---
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  # Use NLB (Layer 4) via AWS Load Balancer Controller
  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
    value = "true"
    type  = "string"
  }

  # --- Ports: HTTP (80) and HTTPS (443) entrypoints ---
  set {
    name  = "ports.web.port"
    value = "8000"
  }

  set {
    name  = "ports.web.exposedPort"
    value = "80"
  }

  set {
    name  = "ports.websecure.port"
    value = "8443"
  }

  set {
    name  = "ports.websecure.exposedPort"
    value = "443"
  }

  # --- Enable Traefik Dashboard (internal access only) ---
  set {
    name  = "ingressRoute.dashboard.enabled"
    value = "true"
  }

  set {
    name  = "ingressRoute.dashboard.matchRule"
    value = "Host(`traefik.localhost`)"
  }

  # --- Enable Kubernetes Ingress provider ---
  set {
    name  = "providers.kubernetesIngress.enabled"
    value = "true"
  }

  set {
    name  = "providers.kubernetesCRD.enabled"
    value = "true"
  }

  # --- Enable access logs ---
  set {
    name  = "logs.access.enabled"
    value = "true"
  }

  # --- Moderate resources for dev ---
  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "500m"
  }

  set {
    name  = "resources.limits.memory"
    value = "512Mi"
  }

  depends_on = [
    module.eks,
    helm_release.aws_lb_controller,
  ]
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "traefik_namespace" {
  value       = kubernetes_namespace.traefik.metadata[0].name
  description = "Namespace where Traefik Ingress Controller is installed"
}
