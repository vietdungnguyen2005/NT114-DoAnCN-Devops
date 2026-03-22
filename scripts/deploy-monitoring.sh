#!/bin/bash
# =============================================================================
# deploy-monitoring.sh — Deploy Full Observability Stack on EKS
# =============================================================================
# Deploys:
#   1. kube-prometheus-stack (Prometheus + Grafana + AlertManager)
#   2. Loki (log aggregation)
#   3. OpenTelemetry Collector (DaemonSet agent)
#   4. ServiceMonitors for travel-web
#   5. AWS CloudWatch agent (optional)
#
# Prerequisites:
#   - kubectl configured for the target cluster
#   - helm v3 installed
#   - monitoring namespace exists (created by setup_cluster.sh)
#
# Usage:
#   ./scripts/deploy-monitoring.sh
#   ./scripts/deploy-monitoring.sh --dry-run
#   ./scripts/deploy-monitoring.sh --uninstall
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

NAMESPACE="monitoring"
DRY_RUN=false
UNINSTALL=false

# --- Parse arguments ---
for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --uninstall) UNINSTALL=true ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] [--uninstall] [--help]"
      echo ""
      echo "  --dry-run    Show what would be deployed without applying"
      echo "  --uninstall  Remove the entire monitoring stack"
      echo "  --help       Show this help"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      exit 1
      ;;
  esac
done

echo "============================================================"
echo "  TRAVEL-WEB — Monitoring Stack Deployment"
echo "============================================================"
echo "  Namespace: $NAMESPACE"
echo "  Dry-run:   $DRY_RUN"
echo "============================================================"
echo ""

# --- Pre-flight checks ---
echo "🔍 Pre-flight checks..."

if ! command -v kubectl &>/dev/null; then
  echo "❌ kubectl not found"
  exit 1
fi

if ! command -v helm &>/dev/null; then
  echo "❌ helm not found. Install: https://helm.sh/docs/intro/install/"
  exit 1
fi

if ! kubectl cluster-info &>/dev/null; then
  echo "❌ kubectl cannot connect to cluster"
  exit 1
fi

echo "✅ All pre-flight checks passed"
echo ""

# --- Uninstall mode ---
if [ "$UNINSTALL" = true ]; then
  echo "🗑️  Uninstalling monitoring stack..."
  echo ""

  echo "   Removing OTel Collector..."
  kubectl delete -f "$PROJECT_ROOT/k8s-manifests/monitoring/otel-collector.yaml" --ignore-not-found 2>/dev/null || true

  echo "   Removing ServiceMonitors..."
  kubectl delete -f "$PROJECT_ROOT/k8s-manifests/monitoring/service-monitors.yaml" --ignore-not-found 2>/dev/null || true

  echo "   Uninstalling Loki..."
  helm uninstall loki -n "$NAMESPACE" 2>/dev/null || true

  echo "   Uninstalling kube-prometheus-stack..."
  helm uninstall monitoring -n "$NAMESPACE" 2>/dev/null || true

  echo "   Cleaning up CRDs..."
  kubectl delete crd prometheuses.monitoring.coreos.com --ignore-not-found 2>/dev/null || true
  kubectl delete crd servicemonitors.monitoring.coreos.com --ignore-not-found 2>/dev/null || true
  kubectl delete crd alertmanagers.monitoring.coreos.com --ignore-not-found 2>/dev/null || true
  kubectl delete crd prometheusrules.monitoring.coreos.com --ignore-not-found 2>/dev/null || true
  kubectl delete crd podmonitors.monitoring.coreos.com --ignore-not-found 2>/dev/null || true

  echo ""
  echo "✅ Monitoring stack uninstalled"
  exit 0
fi

# --- Ensure namespace ---
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# === STEP 1: Add Helm repositories ===
echo "📦 [1/5] Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update
echo "✅ Helm repos updated"
echo ""

# === STEP 2: Deploy kube-prometheus-stack ===
echo "📦 [2/5] Deploying kube-prometheus-stack (Prometheus + Grafana + AlertManager)..."

HELM_CMD="helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE \
  -f $PROJECT_ROOT/k8s-manifests/monitoring/values.yaml \
  --wait --timeout 10m"

if [ "$DRY_RUN" = true ]; then
  echo "   [DRY-RUN] $HELM_CMD --dry-run"
  eval "$HELM_CMD --dry-run" 2>&1 | tail -5
else
  eval "$HELM_CMD"
fi
echo "✅ kube-prometheus-stack deployed"
echo ""

# === STEP 3: Deploy Loki ===
echo "📦 [3/5] Deploying Loki (log aggregation)..."

LOKI_CMD="helm upgrade --install loki grafana/loki \
  --namespace $NAMESPACE \
  -f $PROJECT_ROOT/k8s-manifests/monitoring/loki-values.yaml \
  --wait --timeout 10m"

if [ "$DRY_RUN" = true ]; then
  echo "   [DRY-RUN] $LOKI_CMD --dry-run"
  eval "$LOKI_CMD --dry-run" 2>&1 | tail -5
else
  eval "$LOKI_CMD"
fi
echo "✅ Loki deployed"
echo ""

# === STEP 4: Deploy OpenTelemetry Collector DaemonSet ===
echo "📦 [4/5] Deploying OpenTelemetry Collector (DaemonSet agent)..."

if [ "$DRY_RUN" = true ]; then
  echo "   [DRY-RUN] kubectl apply -f otel-collector.yaml"
  kubectl apply -f "$PROJECT_ROOT/k8s-manifests/monitoring/otel-collector.yaml" --dry-run=client 2>&1 | tail -10
else
  kubectl apply -f "$PROJECT_ROOT/k8s-manifests/monitoring/otel-collector.yaml"
fi
echo "✅ OTel Collector deployed"
echo ""

# === STEP 5: Deploy ServiceMonitors ===
echo "📦 [5/5] Deploying ServiceMonitors..."

if [ "$DRY_RUN" = true ]; then
  echo "   [DRY-RUN] kubectl apply -f service-monitors.yaml"
  kubectl apply -f "$PROJECT_ROOT/k8s-manifests/monitoring/service-monitors.yaml" --dry-run=client 2>&1 | tail -10
else
  kubectl apply -f "$PROJECT_ROOT/k8s-manifests/monitoring/service-monitors.yaml"
fi
echo "✅ ServiceMonitors deployed"
echo ""

# === Optional: AWS CloudWatch Agent ===
echo "📦 [Optional] Checking for AWS CloudWatch integration..."
if kubectl get daemonset cloudwatch-agent -n amazon-cloudwatch &>/dev/null; then
  echo "   ✅ CloudWatch agent already running"
else
  echo "   ℹ️  CloudWatch agent not found."
  echo "   To install, enable the Amazon CloudWatch Observability add-on in EKS console"
  echo "   or run:"
  echo "   aws eks create-addon --cluster-name <CLUSTER> --addon-name amazon-cloudwatch-observability"
fi
echo ""

# === Summary ===
echo "============================================================"
echo "  🎉 Monitoring Stack Deployment Complete!"
echo "============================================================"
echo ""
echo "  Components:"
echo "    ✅ Prometheus        — metrics collection & storage"
echo "    ✅ Grafana           — dashboards & visualization"
echo "    ✅ AlertManager      — alerting"
echo "    ✅ Loki              — log aggregation"
echo "    ✅ OTel Collector    — telemetry pipeline (DaemonSet)"
echo "    ✅ ServiceMonitors   — auto-discovery for travel-web"
echo "    ✅ Node Exporter     — node system metrics"
echo "    ✅ kube-state-metrics — K8s object metrics"
echo ""

# Get Grafana URL
GRAFANA_URL=$(kubectl get svc monitoring-grafana -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
if [ -n "$GRAFANA_URL" ]; then
  echo "  🌐 Grafana URL: http://$GRAFANA_URL"
  echo "     Username: admin"
  echo "     Password: admin (change after first login!)"
else
  echo "  🌐 Grafana: kubectl port-forward svc/monitoring-grafana -n $NAMESPACE 3000:80"
  echo "     Then open: http://localhost:3000"
  echo "     Username: admin / Password: admin"
fi

echo ""
echo "  📊 Prometheus: kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n $NAMESPACE 9090:9090"
echo "  📋 AlertManager: kubectl port-forward svc/monitoring-kube-prometheus-alertmanager -n $NAMESPACE 9093:9093"
echo ""
echo "  📝 Check pods:"
echo "     kubectl get pods -n $NAMESPACE"
echo ""
echo "  📝 Check OTel Collector:"
echo "     kubectl get ds otel-collector-agent -n $NAMESPACE"
echo "     kubectl logs -l app.kubernetes.io/name=otel-collector -n $NAMESPACE --tail=50"
echo "============================================================"
