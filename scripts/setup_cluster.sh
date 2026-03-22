#!/bin/bash
# =============================================================================
# setup_cluster.sh — Bootstrap EKS Cluster for TRAVEL-WEB
# =============================================================================
# Adapted from NT548-DevOps for travel-web project.
# Performs: kubeconfig, namespaces, ECR secret, ArgoCD install, Secrets Manager.
#
# Usage:
#   ./scripts/setup_cluster.sh <CLUSTER_NAME> <AWS_REGION> <ECR_URL>
#
# Example:
#   ./scripts/setup_cluster.sh travel-web-eks ap-southeast-1 123456789.dkr.ecr.ap-southeast-1.amazonaws.com
# =============================================================================
set -euo pipefail

# --- Configuration ---
CLUSTER_NAME=${1:-}
AWS_REGION=${2:-}
ECR_URL=${3:-}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Namespaces for multi-environment setup
NAMESPACES=("travel-web" "travel-web-staging" "travel-web-production" "monitoring" "argocd")

# --- Input validation ---
if [ -z "$CLUSTER_NAME" ] || [ -z "$AWS_REGION" ] || [ -z "$ECR_URL" ]; then
  echo "❌ Error: Missing required parameters!"
  echo ""
  echo "Usage: ./scripts/setup_cluster.sh <CLUSTER_NAME> <AWS_REGION> <ECR_URL>"
  echo ""
  echo "Example:"
  echo "  ./scripts/setup_cluster.sh travel-web-eks ap-southeast-1 123456789.dkr.ecr.ap-southeast-1.amazonaws.com"
  exit 1
fi

echo "============================================================"
echo "  TRAVEL-WEB EKS Cluster Setup"
echo "============================================================"
echo "  Cluster : $CLUSTER_NAME"
echo "  Region  : $AWS_REGION"
echo "  ECR     : $ECR_URL"
echo "============================================================"
echo ""

# --- 1. KUBECONFIG ---
echo "🚀 [1/7] Updating kubeconfig..."
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
echo "✅ Kubeconfig updated"
echo ""

# --- 2. NAMESPACES ---
echo "🚀 [2/7] Creating namespaces..."
for NS in "${NAMESPACES[@]}"; do
  kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
  echo "   ✓ $NS"
done
echo "✅ All namespaces created"
echo ""

# --- 3. ECR SECRET (for all app namespaces) ---
echo "🚀 [3/7] Creating ECR pull secrets (regcred)..."
TOKEN=$(aws ecr get-login-password --region "$AWS_REGION")

for NS in "travel-web" "travel-web-staging" "travel-web-production"; do
  kubectl delete secret regcred -n "$NS" --ignore-not-found
  kubectl create secret docker-registry regcred \
    --docker-server="$ECR_URL" \
    --docker-username=AWS \
    --docker-password="$TOKEN" \
    --namespace="$NS"
  echo "   ✓ regcred in $NS"
done
echo "✅ ECR secrets created"
echo ""

# --- 4. STORAGE CLASS ---
echo "🚀 [4/7] Configuring storage class..."
# Remove default gp2 if it exists and create gp3
kubectl delete sc gp2 --ignore-not-found

cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF
echo "✅ Storage class gp3 configured as default"
echo ""

# --- 5. ARGOCD INSTALL ---
echo "🚀 [5/7] Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for ArgoCD to start (timeout: 300s)..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Expose ArgoCD via LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
echo "✅ ArgoCD installed and exposed"
echo ""

# --- 6. AWS SECRETS MANAGER INTEGRATION ---
echo "🚀 [6/7] Setting up application secrets..."

# Check if secrets exist in environment or AWS Secrets Manager
if command -v aws &>/dev/null; then
  echo "   Attempting to fetch secrets from AWS Secrets Manager..."

  # Fetch database credentials
  DB_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id "travel-web/database" \
    --region "$AWS_REGION" \
    --query 'SecretString' \
    --output text 2>/dev/null || echo "")

  if [ -n "$DB_SECRET" ]; then
    DB_URL=$(echo "$DB_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin).get('DATABASE_URL',''))" 2>/dev/null || echo "")

    if [ -n "$DB_URL" ]; then
      for NS in "travel-web" "travel-web-staging" "travel-web-production"; do
        kubectl create secret generic travel-web-secrets \
          --from-literal=DATABASE_URL="$DB_URL" \
          --namespace="$NS" \
          --dry-run=client -o yaml | kubectl apply -f -
        echo "   ✓ travel-web-secrets in $NS"
      done
      echo "✅ Application secrets created from Secrets Manager"
    else
      echo "⚠️  DATABASE_URL not found in secret. Create secrets manually."
    fi
  else
    echo "⚠️  Secret 'travel-web/database' not found in Secrets Manager."
    echo "   Create it with:"
    echo "   aws secretsmanager create-secret --name travel-web/database \\"
    echo "     --secret-string '{\"DATABASE_URL\":\"postgresql://...\"}'"
  fi
else
  echo "⚠️  AWS CLI not available. Skipping Secrets Manager integration."
fi
echo ""

# --- 7. INSTALL METRICS SERVER (if not present) ---
echo "🚀 [7/7] Checking metrics-server..."
if ! kubectl get deployment metrics-server -n kube-system &>/dev/null; then
  echo "   Installing metrics-server for HPA support..."
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  echo "✅ Metrics server installed"
else
  echo "✅ Metrics server already present"
fi
echo ""

# --- SUMMARY ---
echo "============================================================"
echo "  🎉 CLUSTER SETUP COMPLETE!"
echo "============================================================"

# Wait briefly for LoadBalancer provisioning
echo "⏳ Waiting 15s for LoadBalancer DNS..."
sleep 15

ARGO_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending...")
ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "unavailable")

# Save access info
OUTPUT_FILE="$PROJECT_ROOT/access_info.txt"
cat <<EOF > "$OUTPUT_FILE"
==========================================================
  TRAVEL-WEB — Cluster Access Information
==========================================================
  ArgoCD UI:       https://$ARGO_URL
  ArgoCD User:     admin
  ArgoCD Password: $ARGO_PWD
----------------------------------------------------------
  Cluster:         $CLUSTER_NAME
  Region:          $AWS_REGION
  ECR:             $ECR_URL
----------------------------------------------------------
  Namespaces:
    - travel-web             (dev)
    - travel-web-staging     (staging)
    - travel-web-production  (production)
    - monitoring             (observability)
    - argocd                 (GitOps)
==========================================================
  Next steps:
    1. Deploy monitoring: ./scripts/deploy-monitoring.sh
    2. Deploy ArgoCD apps: ./scripts/deploy-argocd-apps.sh
==========================================================
EOF

echo ""
echo "✅ Access info saved to: $OUTPUT_FILE"
echo ""
echo "  ArgoCD UI:       https://$ARGO_URL"
echo "  ArgoCD User:     admin"
echo "  ArgoCD Password: $ARGO_PWD"
echo ""
echo "  Next steps:"
echo "    1. Deploy monitoring:  ./scripts/deploy-monitoring.sh"
echo "    2. Deploy ArgoCD apps: ./scripts/deploy-argocd-apps.sh"
echo "============================================================"
