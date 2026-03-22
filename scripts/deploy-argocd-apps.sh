#!/bin/bash
# =============================================================================
# deploy-argocd-apps.sh — Deploy TRAVEL-WEB ArgoCD Applications
# =============================================================================
# Creates ArgoCD Application resources for 3 environments:
#   - travel-web-dev        → travel-web namespace
#   - travel-web-staging    → travel-web-staging namespace
#   - travel-web-production → travel-web-production namespace
#
# Usage:
#   ./scripts/deploy-argocd-apps.sh [GIT_REPO_URL]
#
# Example:
#   ./scripts/deploy-argocd-apps.sh https://github.com/your-org/NT114-DoAnCN-Devops.git
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Git repository URL (override via argument or env var)
GIT_REPO=${1:-${ARGOCD_GIT_REPO:-"https://github.com/your-org/NT114-DoAnCN-Devops.git"}}
GIT_BRANCH=${ARGOCD_GIT_BRANCH:-"main"}
K8S_PATH_BASE="k8s-manifests/overlays"

echo "============================================================"
echo "  TRAVEL-WEB — Deploy ArgoCD Applications"
echo "============================================================"
echo "  Git Repo:   $GIT_REPO"
echo "  Branch:     $GIT_BRANCH"
echo "  K8s Path:   $K8S_PATH_BASE"
echo "============================================================"
echo ""

# --- Pre-flight checks ---
if ! kubectl cluster-info &>/dev/null; then
  echo "❌ Error: kubectl is not configured or cluster is not accessible"
  exit 1
fi

if ! kubectl get namespace argocd &>/dev/null; then
  echo "❌ Error: ArgoCD namespace not found"
  echo ""
  echo "Install ArgoCD first:"
  echo "  ./scripts/setup_cluster.sh <CLUSTER_NAME> <REGION> <ECR_URL>"
  exit 1
fi

echo "✅ Pre-flight checks passed"
echo ""

# --- Deploy ArgoCD Applications ---
declare -A ENVIRONMENTS
ENVIRONMENTS=(
  ["dev"]="travel-web"
  ["staging"]="travel-web-staging"
  ["production"]="travel-web-production"
)

for ENV in dev staging production; do
  NAMESPACE="${ENVIRONMENTS[$ENV]}"
  APP_NAME="travel-web-${ENV}"

  echo "📦 Deploying ArgoCD Application: $APP_NAME → $NAMESPACE"

  cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${APP_NAME}
  namespace: argocd
  labels:
    app.kubernetes.io/name: travel-web
    app.kubernetes.io/part-of: travel-web
    environment: ${ENV}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: ${GIT_REPO}
    targetRevision: ${GIT_BRANCH}
    path: ${K8S_PATH_BASE}/${ENV}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 3
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m0s
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas
EOF

  echo "   ✅ $APP_NAME applied"
  echo ""
done

# --- Deploy monitoring application via ArgoCD ---
echo "📦 Deploying ArgoCD Application: travel-web-monitoring"
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: travel-web-monitoring
  namespace: argocd
  labels:
    app.kubernetes.io/name: travel-web
    app.kubernetes.io/part-of: travel-web
    environment: shared
spec:
  project: default
  source:
    repoURL: ${GIT_REPO}
    targetRevision: ${GIT_BRANCH}
    path: k8s-manifests/monitoring
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
echo "   ✅ travel-web-monitoring applied"
echo ""

# --- Status ---
echo "============================================================"
echo "  ✅ All ArgoCD Applications Deployed!"
echo "============================================================"
echo ""
echo "📊 Application status:"
kubectl get applications -n argocd -o wide 2>/dev/null || echo "   (waiting for sync...)"
echo ""
echo "🔍 Commands:"
echo "   kubectl get applications -n argocd"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   Open: https://localhost:8080"
echo ""
echo "🔑 ArgoCD admin password:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""

# --- Wait for service URLs (optional) ---
echo "⏳ Waiting for LoadBalancer endpoints (max 120s)..."
COUNTER=0
MAX_WAIT=24

while [ $COUNTER -lt $MAX_WAIT ]; do
  DEV_URL=$(kubectl get svc travel-web -n travel-web -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
  STAGING_URL=$(kubectl get svc travel-web -n travel-web-staging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
  PROD_URL=$(kubectl get svc travel-web -n travel-web-production -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

  if [ -n "$DEV_URL" ] && [ -n "$STAGING_URL" ] && [ -n "$PROD_URL" ]; then
    echo ""
    echo "🌐 Service URLs:"
    echo "   Dev:        http://$DEV_URL"
    echo "   Staging:    http://$STAGING_URL"
    echo "   Production: http://$PROD_URL"
    break
  fi

  COUNTER=$((COUNTER + 1))
  sleep 5
  [ $((COUNTER % 4)) -eq 0 ] && echo "   Still waiting... ($((COUNTER * 5))s / 120s)"
done

if [ $COUNTER -ge $MAX_WAIT ]; then
  echo ""
  echo "⚠️  Some LoadBalancers are still provisioning."
  echo "   Check later with:"
  echo "   kubectl get svc -n travel-web"
  echo "   kubectl get svc -n travel-web-staging"
  echo "   kubectl get svc -n travel-web-production"
fi

echo ""
echo "============================================================"
