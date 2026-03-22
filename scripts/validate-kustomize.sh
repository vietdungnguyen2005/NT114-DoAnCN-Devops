#!/bin/bash
# =============================================================================
# validate-kustomize.sh — Validate All Kustomize Configurations
# =============================================================================
# Validates base and overlay Kustomize configs for TRAVEL-WEB.
# Runs from the project root.
#
# Usage:
#   ./scripts/validate-kustomize.sh
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "============================================================"
echo "  TRAVEL-WEB — Kustomize Validation"
echo "============================================================"
echo ""

cd "$PROJECT_ROOT"

# --- Pre-flight ---
if ! command -v kubectl &>/dev/null; then
  echo "❌ Error: kubectl is not installed"
  exit 1
fi

echo "✓ Using kubectl kustomize (built-in)"
echo ""

ERRORS=0

# --- Validate base ---
echo "📦 Validating base configuration..."
if [ -d "k8s-manifests/base" ]; then
  if kubectl kustomize k8s-manifests/base >/dev/null 2>&1; then
    RESOURCE_COUNT=$(kubectl kustomize k8s-manifests/base | grep -c "^kind:" || echo "0")
    echo "   ✅ Base is valid ($RESOURCE_COUNT resources)"
  else
    echo "   ❌ Base has errors:"
    kubectl kustomize k8s-manifests/base 2>&1 | sed 's/^/      /'
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "   ⚠️  k8s-manifests/base not found — skipping"
fi
echo ""

# --- Validate overlays ---
for ENV in dev staging production; do
  OVERLAY_PATH="k8s-manifests/overlays/$ENV"

  echo "📦 Validating $ENV overlay..."

  if [ ! -d "$OVERLAY_PATH" ]; then
    echo "   ⚠️  $OVERLAY_PATH not found — skipping"
    echo ""
    continue
  fi

  if kubectl kustomize "$OVERLAY_PATH" >/dev/null 2>&1; then
    RESOURCE_COUNT=$(kubectl kustomize "$OVERLAY_PATH" | grep -c "^kind:" || echo "0")
    echo "   ✅ $ENV overlay is valid ($RESOURCE_COUNT resources)"

    # Optional: dry-run server-side validation
    if [ "${VALIDATE_SERVER:-false}" = "true" ]; then
      echo "   🔍 Server-side dry-run for $ENV..."
      if kubectl kustomize "$OVERLAY_PATH" | kubectl apply --dry-run=server -f - >/dev/null 2>&1; then
        echo "   ✅ Server-side validation passed"
      else
        echo "   ⚠️  Server-side validation failed (cluster may not be available)"
      fi
    fi
  else
    echo "   ❌ $ENV overlay has errors:"
    kubectl kustomize "$OVERLAY_PATH" 2>&1 | sed 's/^/      /'
    ERRORS=$((ERRORS + 1))
  fi
  echo ""
done

# --- Validate monitoring manifests ---
echo "📦 Validating monitoring manifests..."
MONITORING_PATH="k8s-manifests/monitoring"
if [ -d "$MONITORING_PATH" ]; then
  for FILE in "$MONITORING_PATH"/*.yaml; do
    if [ -f "$FILE" ]; then
      BASENAME=$(basename "$FILE")
      # Skip Helm values files (not standalone K8s manifests)
      if [[ "$BASENAME" == *"values"* ]] || [[ "$BASENAME" == *"loki-values"* ]]; then
        echo "   ⏭️  $BASENAME (Helm values — skip)"
        continue
      fi
      if kubectl apply --dry-run=client -f "$FILE" >/dev/null 2>&1; then
        echo "   ✅ $BASENAME is valid"
      else
        echo "   ❌ $BASENAME has errors:"
        kubectl apply --dry-run=client -f "$FILE" 2>&1 | sed 's/^/      /'
        ERRORS=$((ERRORS + 1))
      fi
    fi
  done
else
  echo "   ⚠️  $MONITORING_PATH not found — skipping"
fi
echo ""

# --- Summary ---
echo "============================================================"
if [ $ERRORS -eq 0 ]; then
  echo "  🎉 All Kustomize configurations are valid!"
else
  echo "  ❌ Found $ERRORS error(s). Please fix and re-run."
fi
echo "============================================================"

exit $ERRORS
