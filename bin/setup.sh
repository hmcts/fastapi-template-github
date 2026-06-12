#!/usr/bin/env bash
set -euo pipefail

# ─── Colours ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()    { echo -e "${GREEN}✔${NC}  $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
die()     { echo -e "${RED}✘${NC}  $*" >&2; exit 1; }

# ─── Validate running from repo root ────────────────────────────────────────
[[ -f "pyproject.toml" && -d "charts" ]] || \
  die "Run this script from the root of your repository."

# ─── Check this hasn't already been run ─────────────────────────────────────
if ! grep -q "myproduct" pyproject.toml 2>/dev/null; then
  die "Placeholders have already been replaced. Nothing to do."
fi

# ─── Prompt for product and component names ──────────────────────────────────
echo ""
echo "  HMCTS FastAPI template setup"
echo "  ─────────────────────────────"
echo ""

read -rp "  Product name   (e.g. cmc):         " PRODUCT
read -rp "  Component name (e.g. claim-store):  " COMPONENT

echo ""

# ─── Validate inputs ─────────────────────────────────────────────────────────
[[ -n "$PRODUCT" ]]   || die "Product name cannot be empty."
[[ -n "$COMPONENT" ]] || die "Component name cannot be empty."

[[ "$PRODUCT"   =~ ^[a-z0-9-]+$ ]] || die "Product name must be lowercase alphanumeric with hyphens only."
[[ "$COMPONENT" =~ ^[a-z0-9-]+$ ]] || die "Component name must be lowercase alphanumeric with hyphens only."

# ─── Files to update in-place ────────────────────────────────────────────────
FILES=(
  pyproject.toml
  catalog-info.yaml
  Jenkinsfile_template
  Jenkinsfile_nightly
  "charts/myproduct-mycomponent/Chart.yaml"
  "charts/myproduct-mycomponent/values.yaml"
  "charts/myproduct-mycomponent/values.preview.template.yaml"
  "charts/myproduct-mycomponent/values.aat.template.yaml"
  README.md
)

for file in "${FILES[@]}"; do
  if [[ -f "$file" ]]; then
    sed -i.bak \
      -e "s/myproduct-mycomponent/${PRODUCT}-${COMPONENT}/g" \
      -e "s/myproduct/${PRODUCT}/g" \
      -e "s/mycomponent/${COMPONENT}/g" \
      "$file"
    rm -f "${file}.bak"
    info "Updated $file"
  else
    warn "Skipped $file (not found)"
  fi
done

# ─── Rename Helm chart directory ─────────────────────────────────────────────
if [[ -d "charts/myproduct-mycomponent" ]]; then
  mv "charts/myproduct-mycomponent" "charts/${PRODUCT}-${COMPONENT}"
  info "Renamed charts/myproduct-mycomponent → charts/${PRODUCT}-${COMPONENT}"
fi

# ─── Rename Jenkinsfile_template → Jenkinsfile_CNP ───────────────────────────
if [[ -f "Jenkinsfile_template" ]]; then
  mv "Jenkinsfile_template" "Jenkinsfile_CNP"
  info "Renamed Jenkinsfile_template → Jenkinsfile_CNP"
fi

# ─── Done ────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}Setup complete!${NC}"
echo ""
echo "  Next steps:"
echo "  1. Review the changes with: git diff"
echo "  2. Commit: git add -A && git commit -m 'chore: initialise from fastapi-template-github'"
echo "  3. Follow the README to register your service with Jenkins."
echo ""
