# PROMPT — Hướng Dẫn Tiếp Tục Phát Triển Dự Án NT114-DoAnCN-Devops

> **Mục đích file này**: Cung cấp ĐỦ thông tin để bất kỳ AI/developer nào cũng có thể tiếp tục code, sửa lỗi và hoàn thiện dự án mà không cần hỏi thêm context.

---

## 1. TỔNG QUAN DỰ ÁN

**Repo chính**: `D:\NT114-DoAnCN-Devops\NT114-DoAnCN-Devops`
**GitLab**: `https://gitlab.com/vietdungnguyen2005/NT114-DoAnCN-Devops.git` (primary — CI/CD chạy ở đây)
**GitHub** (mirror): `https://github.com/vietdungnguyen2005/NT114-DoAnCN-Devops.git` (giữ lại, không dùng CI/CD)
**Ứng dụng web** (submodule): `web/TRAVEL-WEB` → `https://gitlab.com/vietdungnguyen2005/TRAVEL-WEB.git`
**TRAVEL-WEB GitHub** (mirror): `https://github.com/vietdungnguyen2005/TRAVEL-WEB.git`

> **QUAN TRỌNG**: Dự án đã chuyển sang **GitLab** làm nền tảng chính. CI/CD dùng **GitLab CI/CD** (`.gitlab-ci.yml`), KHÔNG dùng GitHub Actions (`.github/workflows/` chỉ giữ lại để tham khảo).

**Ứng dụng**: Website đặt phòng khách sạn (Travel/Hotel Booking) xây trên **Next.js 16 + React 19 + TypeScript 5 + Prisma ORM + PostgreSQL + Stripe + Cloudinary**.

**Mục tiêu DevOps**: Xây dựng hệ thống CI/CD, GitOps, hạ tầng AWS, và giám sát hoàn chỉnh cho ứng dụng trên.

---

## 2. KIẾN TRÚC 4 PHÂN HỆ

### Phân hệ 1: CI/CD Pipeline (GitLab CI/CD)
```
Developer → Commit → GitLab Repository
  ↓
CI Pipeline (.gitlab-ci.yml):
  1. Lint & Static Check (ESLint + TypeScript tsc)
  2. SonarQube/SonarCloud (phân tích chất lượng code TS/JS)
  3. Unit & Integration Tests (Jest)
  4. Build Docker Image (multi-stage, standalone Next.js)
  5. Trivy Vulnerability Scan (filesystem + image)
  6. Sign Image (Cosign keyless OIDC)
  7. Push → Amazon ECR (travel-web-app)
  8. Update Kustomize values → GitOps trigger
```

### Phân hệ 2: GitOps Release Flow (ArgoCD + Argo Rollouts)
```
GitOps Config Repo (ci-cd/k8s/) ← CI cập nhật image tag
  ↓
ArgoCD theo dõi repo, phát hiện thay đổi
  ↓
1. Deploy to Staging → Smoke Tests
2. Promote to Production → Canary Rollouts (20%→40%→60%→80%→100%)
```

### Phân hệ 3: AWS Cloud & EKS Kubernetes
```
End User → Internet Gateway → ALB (Public Subnets)
  → Traefik Ingress (Private Subnets)
  → Next.js Pods (với HPA auto-scaling)
  → Amazon RDS PostgreSQL
  → Amazon S3 (static assets)
  → AWS Secrets Manager (env secrets)

Terraform quản lý toàn bộ hạ tầng bằng IaC.
```

### Phân hệ 4: Observability Stack
```
OTel Collector (DaemonSet trong EKS)
  ├→ Prometheus (Metrics: CPU, RAM, request rates)
  ├→ Loki (Logs: application logs, error logs)
  └→ Grafana (Dashboards trực quan)

AWS CloudWatch ← Infrastructure metrics (ALB, RDS, EKS)
```

---

## 3. CẤU TRÚC THƯ MỤC ĐẦY ĐỦ

```
NT114-DoAnCN-Devops/
├── .gitlab-ci.yml                  # [CHÍNH] GitLab CI/CD Pipeline (thay thế GitHub Actions)
├── .github/workflows/              # [THAM KHẢO] GitHub Actions CI/CD (không dùng nữa)
│   ├── ci-cd-pipeline.yml          # Smart CI/CD Pipeline chính (8 stages) — ĐÃ THAY BẰNG .gitlab-ci.yml
│   ├── update-submodule.yml        # Sync submodule TRAVEL-WEB — ĐÃ THAY BẰNG .gitlab-ci.yml
│   └── validate-manifests.yml      # Validate K8s manifests trên PR — ĐÃ THAY BẰNG .gitlab-ci.yml
│
├── ci-cd/                          # CI/CD, K8s, ArgoCD configs
│   ├── argocd/                     # ArgoCD Application manifests
│   │   ├── travel-web-dev.yaml     # Dev env (track test branch)
│   │   ├── travel-web-staging.yaml # Staging env
│   │   └── travel-web-production.yaml # Production (track main, canary)
│   ├── docker/
│   │   └── Dockerfile              # Multi-stage Next.js production Dockerfile
│   ├── k8s/
│   │   ├── base/                   # Kustomize base resources
│   │   │   ├── kustomization.yaml
│   │   │   ├── namespace.yaml
│   │   │   ├── deployment.yaml     # Argo Rollout (canary strategy)
│   │   │   ├── service.yaml        # ClusterIP + Traefik IngressRoute
│   │   │   ├── hpa.yaml            # HPA: min 2, max 10, 70% CPU
│   │   │   ├── db-migration-job.yaml  # PreSync hook: prisma migrate
│   │   │   ├── external-secret.yaml   # AWS Secrets Manager integration
│   │   │   └── storage-class.yaml     # gp2 EBS CSI
│   │   └── overlays/               # Per-environment overrides
│   │       ├── dev/                 # 1 replica, debug mode
│   │       ├── staging/             # 2 replicas
│   │       └── production/          # 3 replicas, higher resources
│   ├── sonarqube/
│   │   └── sonar-project.properties # SonarCloud config cho TypeScript
│   └── trivy/
│       └── .trivyignore             # CVE ignore list
│
├── infrastructure/                  # Terraform IaC (từ D:\Infra\TRAVEL-WEB, đã adapt)
│   ├── bootstrap/main.tf           # S3 + DynamoDB cho Terraform state (chạy 1 lần)
│   ├── providers.tf                # AWS + Helm + Kubernetes providers
│   ├── backend.tf                  # S3 backend (bỏ comment sau bootstrap)
│   ├── locals.tf                   # Local values + random suffix
│   ├── variables.tf                # Tất cả biến cấu hình
│   ├── outputs.tf                  # Output sau terraform apply
│   ├── vpc.tf                      # VPC + Subnets + NAT Gateway
│   ├── security-groups.tf          # ALB → App(3000) → RDS
│   ├── ecr.tf                      # 1 ECR repo: travel-web-app
│   ├── s3.tf                       # Static assets bucket + Logs bucket
│   ├── eks.tf                      # EKS cluster + worker nodes
│   ├── rds.tf                      # RDS PostgreSQL 16 (db: travelweb)
│   ├── argocd.tf                   # ArgoCD Helm release + Application
│   ├── alb-controller.tf           # AWS Load Balancer Controller (IRSA)
│   ├── traefik-ingress.tf          # Traefik Ingress Controller (thay Nginx)
│   ├── vpc-endpoints.tf            # S3 Gateway Endpoint (tiết kiệm NAT)
│   ├── secrets-manager.tf          # AWS Secrets Manager + IRSA cho pods
│   └── terraform.tfvars.example    # Template biến
│
├── k8s-manifests/monitoring/        # K8s monitoring manifests cho EKS
│   ├── values.yaml                  # kube-prometheus-stack Helm values
│   ├── service-monitors.yaml        # ServiceMonitor cho travel-web
│   ├── otel-collector.yaml          # OTel Collector DaemonSet
│   └── loki-values.yaml             # Loki Helm values
│
├── monitoring/                      # Local dev monitoring configs
│   ├── prometheus.yml               # Prometheus scrape config
│   ├── loki-config.yaml             # Loki single-process config
│   └── grafana/provisioning/        # Grafana auto-provision
│       ├── datasources/datasource.yml  # Prometheus + Loki sources
│       └── dashboards/
│           ├── dashboard-provider.yml
│           └── travel-web-dashboard.json  # 13-panel dashboard
│
├── scripts/                         # Bash deployment scripts
│   ├── setup_cluster.sh             # Bootstrap EKS cluster
│   ├── deploy-argocd-apps.sh        # Deploy ArgoCD Applications
│   ├── validate-kustomize.sh        # Validate K8s configs
│   └── deploy-monitoring.sh         # Deploy monitoring stack
│
├── docker-compose.yml               # Local dev: Next.js + PostgreSQL + Prometheus + Grafana + Loki
├── .gitignore                       # Comprehensive ignore
├── .gitmodules                      # Submodule config
│
└── web/TRAVEL-WEB/                  # [SUBMODULE] Next.js application
    ├── src/                         # Source code
    │   ├── app/                     # Next.js App Router
    │   │   ├── (admin)/             # Admin dashboard
    │   │   ├── (auth)/              # Authentication pages
    │   │   ├── (customer)/          # Customer-facing pages
    │   │   └── api/                 # REST API routes (~30 endpoints)
    │   ├── components/              # React components (UI, layout, booking, reviews)
    │   ├── lib/                     # Utility functions, auth, Prisma, Stripe, security
    │   ├── store/                   # Zustand state management
    │   └── types/                   # TypeScript definitions
    ├── prisma/                      # Database schema + migrations + seed
    ├── package.json                 # Dependencies
    ├── next.config.ts               # Next.js config (security headers)
    ├── jest.config.js               # Jest testing config
    └── tsconfig.json                # TypeScript config
```

---

## 4. CÔNG NGHỆ SỬ DỤNG

| Lớp | Công nghệ | Phiên bản | Mục đích |
|-----|-----------|-----------|----------|
| **Frontend + Backend** | Next.js | 16.1 | Full-stack React framework |
| **Language** | TypeScript | 5 | Type safety |
| **ORM** | Prisma | 7.2 | Database access |
| **Database** | PostgreSQL | 16 | Relational database |
| **Auth** | NextAuth.js | 5.0-beta | Authentication |
| **Payments** | Stripe | 20.1 | Payment processing |
| **Images** | Cloudinary | 2.8 | Image CDN |
| **UI** | Tailwind CSS + Shadcn/UI | 4 | Styling |
| **Testing** | Jest + Testing Library | 30.2 | Unit/Integration tests |
| **Linting** | ESLint | 9 | Code quality |
| **Container** | Docker | - | Containerization |
| **Registry** | Amazon ECR | - | Container images |
| **Orchestration** | Kubernetes (EKS) | 1.30 | Pod management |
| **IaC** | Terraform | >= 1.5 | Infrastructure automation |
| **CI/CD** | GitLab CI/CD | - | Build/test/deploy automation |
| **GitOps** | ArgoCD + Argo Rollouts | - | Declarative deployment + Canary |
| **Ingress** | Traefik | - | Reverse proxy / routing |
| **Load Balancer** | AWS ALB/NLB | - | Traffic entry point |
| **Secrets** | AWS Secrets Manager | - | Secure secret storage |
| **Metrics** | Prometheus | - | Time-series metrics |
| **Logs** | Loki | - | Log aggregation |
| **Traces** | OpenTelemetry | - | Distributed observability |
| **Dashboards** | Grafana | - | Visualization |
| **Cloud** | AWS (ap-southeast-1) | - | Cloud provider |

---

## 5. LUỒNG HOẠT ĐỘNG CHI TIẾT

### 5.1 CI Pipeline Flow (GitLab CI/CD — `.gitlab-ci.yml`)
```
1. Developer push code → web/TRAVEL-WEB submodule (trên GitLab, nhánh microservice)
2. TRAVEL-WEB repo triggers pipeline trigger / webhook → NT114 pipeline
3. .gitlab-ci.yml chạy 7 stages:
   a. detect: git diff phát hiện file thay đổi → quyết định STRATEGY
      - API/core changes → full_test (full test + scan + build)
      - Static/template changes → light_scan (trivy + build)
      - K8s only → manifest_only (deploy manifests only)
      - CI-only / nothing → skip
   b. validate: Kustomize build + yamllint (chỉ trên MR khi k8s/ thay đổi)
   c. test: ESLint + tsc --noEmit + Jest + SonarCloud (khi STRATEGY == full_test)
   d. scan: Trivy filesystem vulnerability scan (khi STRATEGY != skip)
   e. build: Docker build → Trivy image scan → Cosign sign → Push ECR
   f. deploy: Kustomize edit set image → git commit [skip ci] → push
   g. sync-submodule: Update submodule (chỉ khi trigger via API/web)

Nhánh pipeline: microservice + test (dev) | main (production, sau khi merge)
```

### 5.2 GitOps Flow
```
1. CI commit cập nhật image tag trong ci-cd/k8s/overlays/{env}/kustomization.yaml
2. ArgoCD detect thay đổi (tự động sync vì auto-sync enabled)
3. PreSync Hook: db-migration-job chạy `npx prisma migrate deploy`
4. Argo Rollout triển khai:
   - Dev: trực tiếp replace
   - Staging: deploy + smoke test
   - Production: canary 20% → 40% → 60% → 80% → 100% (mỗi bước pause 30s)
5. Traefik IngressRoute phân phối traffic theo weight
6. Nếu lỗi → automatic rollback
```

### 5.3 Network Flow
```
End User → Internet
  → AWS Internet Gateway
  → Application Load Balancer (Public Subnets)
  → Traefik Ingress Controller (Private Subnets, NLB)
  → Next.js Pods (port 3000)
  → RDS PostgreSQL (Private Subnets, port 5432)
  → S3 (static assets, via VPC Endpoint - free)
  → Secrets Manager (via IRSA, app secrets)
```

### 5.4 Monitoring Flow
```
Next.js Pods → OTel Collector (DaemonSet)
  ├→ Prometheus (metrics: HTTP rates, latency, errors, CPU, RAM)
  ├→ Loki (logs: application logs, error traces)
  └→ Grafana (dashboards: 13 panels)

AWS Services → CloudWatch → Grafana (CloudWatch datasource)
```

---

## 6. CÁC BIẾN MÔI TRƯỜNG QUAN TRỌNG

### 6.1 GitLab CI/CD Variables (Settings → CI/CD → Variables trên repo NT114-DoAnCN-Devops)

> **QUAN TRỌNG**: Biến CI/CD chỉ cần add vào repo **NT114-DoAnCN-Devops** trên GitLab. Repo TRAVEL-WEB KHÔNG cần add biến.

| Variable | Mục đích | Protect | Mask | Expand | Trạng thái |
|----------|----------|---------|------|--------|------------|
| `SONAR_TOKEN` | SonarCloud authentication | ❌ | ✅ | ❌ | ✅ Đã add |
| `DEVOPS_PAT` | GitLab Personal Access Token (scopes: `read_repository`, `write_repository`, `read_api`) cho submodule update | ❌ | ✅ | ❌ | ✅ Đã add |
| `AWS_ACCESS_KEY_ID` | AWS authentication cho ECR push | ❌ | ✅ | ❌ | ⚠️ Thêm khi triển khai AWS |
| `AWS_SECRET_ACCESS_KEY` | AWS authentication cho ECR push | ❌ | ✅ | ❌ | ⚠️ Thêm khi triển khai AWS |

> **Lưu ý**: `$CI_JOB_TOKEN` (tương đương `GITHUB_TOKEN`) được GitLab cung cấp tự động, không cần tạo.

### 6.2 AWS Secrets Manager (travel-web/secrets)
| Key | Mục đích |
|-----|----------|
| `DATABASE_URL` | PostgreSQL connection string |
| `NEXTAUTH_SECRET` | NextAuth signing key |
| `STRIPE_SECRET_KEY` | Stripe payment API key |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook verification |
| `CLOUDINARY_API_KEY` | Cloudinary image upload |
| `CLOUDINARY_API_SECRET` | Cloudinary authentication |
| `RESEND_API_KEY` | Email service |

### 6.3 Terraform Variables (terraform.tfvars)
| Variable | Default | Mô tả |
|----------|---------|-------|
| `aws_region` | `ap-southeast-1` | AWS region |
| `name` | `travel-web` | Prefix cho tất cả resources |
| `vpc_cidr` | `10.0.0.0/16` | VPC network range |
| `kubernetes_version` | `1.30` | EKS version |
| `node_instance_type` | `t3.medium` | Worker node size |
| `node_min/max/desired_size` | `1/3/1` | Auto-scaling config |
| `rds_db_name` | `travelweb` | Database name |
| `rds_password` | *(sensitive)* | DB password |

---

## 7. TRÌNH TỰ TRIỂN KHAI

### Bước 1: Bootstrap Terraform State
```bash
cd infrastructure/bootstrap
terraform init
terraform apply -auto-approve
```

### Bước 2: Triển khai hạ tầng AWS
```bash
cd infrastructure
# Bỏ comment backend "s3" trong backend.tf
terraform init -migrate-state
cp terraform.tfvars.example terraform.tfvars
# Điền password RDS và các biến khác
terraform plan -out=tfplan
terraform apply tfplan
# Chờ 15-20 phút cho EKS cluster
```

### Bước 3: Cấu hình kubectl
```bash
aws eks update-kubeconfig --region ap-southeast-1 --name travel-web-eks
```

### Bước 4: Bootstrap EKS Cluster
```bash
chmod +x scripts/*.sh
./scripts/setup_cluster.sh travel-web-eks ap-southeast-1 <ECR_URL>
```

### Bước 5: Tạo secrets trong AWS Secrets Manager
```bash
aws secretsmanager create-secret --name "travel-web/secrets" \
  --secret-string '{"DATABASE_URL":"...", "NEXTAUTH_SECRET":"...", ...}'
```

### Bước 6: Deploy ArgoCD Applications
```bash
./scripts/deploy-argocd-apps.sh
```

### Bước 7: Deploy Monitoring Stack
```bash
./scripts/deploy-monitoring.sh
```

### Bước 8: Build & Push Docker Image lần đầu
```bash
# Từ CI hoặc manual:
docker build -t travel-web-app -f ci-cd/docker/Dockerfile web/TRAVEL-WEB/
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 443014729163.dkr.ecr.ap-southeast-1.amazonaws.com
docker tag travel-web-app:latest 443014729163.dkr.ecr.ap-southeast-1.amazonaws.com/travel-web-app:latest
docker push 443014729163.dkr.ecr.ap-southeast-1.amazonaws.com/travel-web-app:latest
```

---

## 8. NHỮNG GÌ ĐÃ HOÀN THÀNH ✅

| Phân hệ | Trạng thái | Chi tiết |
|----------|-----------|----------|
| **Terraform IaC** | ✅ Hoàn chỉnh | VPC, EKS, RDS, ECR, S3, ALB Controller, Traefik, ArgoCD, Secrets Manager, VPC Endpoints |
| **CI/CD Pipeline** | ✅ Hoàn chỉnh | `.gitlab-ci.yml` đã tạo (7 stages: detect → validate → test → scan → build → deploy → sync-submodule). `.github/workflows/` giữ lại tham khảo |
| **K8s Manifests** | ✅ Hoàn chỉnh | Kustomize base + 3 overlays, Argo Rollout, HPA, DB migration, External Secrets |
| **ArgoCD GitOps** | ✅ Hoàn chỉnh | 3 environments, canary rollout strategy |
| **Monitoring** | ✅ Hoàn chỉnh | Prometheus, Loki, Grafana, OTel Collector, ServiceMonitors |
| **Deployment Scripts** | ✅ Hoàn chỉnh | setup_cluster, deploy-argocd, deploy-monitoring, validate-kustomize |
| **Docker** | ✅ Hoàn chỉnh | Multi-stage Dockerfile, docker-compose for local dev |
| **.gitignore** | ✅ Hoàn chỉnh | Terraform, Node.js, secrets, IDE |

---

## 9. NHỮNG GÌ CẦN LÀM TIẾP / CÓ THỂ CẦN SỬA ⚠️

### 9.1 Bắt buộc sửa trong submodule TRAVEL-WEB
| Mục | Lý do | File |
|-----|-------|------|
| Thêm `output: "standalone"` vào next.config.ts | Dockerfile dùng standalone mode để tối ưu image size | `web/TRAVEL-WEB/next.config.ts` |
| Thêm `/api/metrics` endpoint | Prometheus cần scrape metrics từ app | `web/TRAVEL-WEB/src/app/api/metrics/route.ts` |
| Thêm `/api/health` endpoint đầy đủ | Kubernetes liveness/readiness probes | Kiểm tra `web/TRAVEL-WEB/src/app/api/health/route.ts` |

### 9.2 Cần kiểm tra và điều chỉnh
| Mục | Chi tiết |
|-----|----------|
| ~~**ACCOUNT_ID trong ECR**~~ | ✅ **ĐÃ SỬA** — Đã thay bằng `443014729163` (từ `D:\Infra\TRAVEL-WEB`) trong tất cả file. Giá trị cũ `540649423715` từ NT548-DevOps đã bị xóa. |
| ~~**GitHub Secrets**~~ | ✅ **ĐÃ CHUYỂN SANG GITLAB** — Dùng GitLab CI/CD Variables thay thế. `SONAR_TOKEN` và `DEVOPS_PAT` đã add vào repo NT114 trên GitLab. |
| **Terraform variables** | Tạo `terraform.tfvars` từ `terraform.tfvars.example`, điền giá trị thực |
| **SonarCloud project** | Tạo project trên SonarCloud, cập nhật `sonar-project.properties` |
| ~~**.gitlab-ci.yml**~~ | ✅ **ĐÃ TẠO** — `.gitlab-ci.yml` 7 stages thay thế 3 file GitHub Actions. Nhánh chính hiện tại: `microservice` (thay `main`). |
| **AWS Secrets Manager** | Tạo secret `travel-web/secrets` với các keys thực tế |
| **Traefik CRDs** | Kiểm tra Traefik CRDs (IngressRoute, TraefikService) đã được cài |
| **Argo Rollouts CRDs** | Cài Argo Rollouts controller: `kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml` |
| **External Secrets Operator** | Cài ESO: `helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace` |
| **Cosign** | Cài cosign cho image signing (hoặc bỏ bước sign nếu không cần) |

### 9.3 Tùy chọn nâng cao (chưa implement)
| Mục | Mô tả |
|-----|-------|
| **Slack/Email alerts** | Cấu hình AlertManager gửi notification khi có lỗi |
| **AWS WAF** | Web Application Firewall trước ALB |
| **Route53** | Custom domain name |
| **ACM Certificate** | HTTPS/TLS certificate |
| **Smoke test script** | Viết smoke test chạy sau staging deploy |
| **Load testing** | k6 hoặc Artillery stress test |
| **Backup automation** | RDS snapshot + S3 cross-region replication |
| **Cost monitoring** | AWS Cost Explorer alerts |

---

## 10. LỆNH HAY DÙNG

### Terraform
```bash
cd infrastructure
terraform init                    # Khởi tạo
terraform plan                    # Xem trước thay đổi
terraform apply                   # Áp dụng thay đổi
terraform destroy                 # Xóa toàn bộ hạ tầng
terraform output                  # Xem outputs (endpoints, URLs)
```

### Kubernetes
```bash
kubectl get pods -A                              # Xem tất cả pods
kubectl get rollout -n travel-web                 # Xem Argo Rollout status
kubectl get applications -n argocd                # Xem ArgoCD apps
kubectl logs -n travel-web -l app=travel-web      # Xem app logs
kubectl port-forward svc/argocd-server -n argocd 8080:443  # ArgoCD UI
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80  # Grafana
```

### Docker
```bash
docker-compose up -d              # Start local dev stack
docker-compose logs -f travel-web # Xem app logs
docker build -f ci-cd/docker/Dockerfile -t travel-web web/TRAVEL-WEB/  # Build image
```

### Kustomize
```bash
kubectl kustomize ci-cd/k8s/base                    # Preview base
kubectl kustomize ci-cd/k8s/overlays/dev             # Preview dev
kubectl kustomize ci-cd/k8s/overlays/production      # Preview production
```

---

## 11. NGUỒN GỐC CODE & BIẾN HẠ TẦNG

> **QUAN TRỌNG**: Tất cả biến hạ tầng AWS (Account ID, ECR URL, Region, VPC CIDR...) phải lấy từ `D:\Infra\TRAVEL-WEB`, **KHÔNG** lấy từ `D:\NT548-DevOps\NT548-DevOps`.

### 11.1 Biến hạ tầng (từ D:\Infra\TRAVEL-WEB)
| Biến | Giá trị | Nguồn file |
|------|---------|------------|
| **AWS Account ID** | `443014729163` | `infrastructure/SETUP_AWS_PERMISSIONS.md` |
| **AWS Region** | `ap-southeast-1` | `infrastructure/variables.tf` |
| **ECR Registry URL** | `443014729163.dkr.ecr.ap-southeast-1.amazonaws.com` | `push-to-ecr.ps1` |
| **ECR Repository** | `travel-web-app` (đã đổi từ `my-ai-platform-*`) | Đặt tên mới cho project |
| **VPC CIDR** | `10.0.0.0/16` | `infrastructure/variables.tf` |
| **EKS Version** | `1.30` | `infrastructure/variables.tf` |
| **Node Instance Type** | `t3.medium` | `infrastructure/variables.tf` |
| **RDS Engine** | PostgreSQL 16 | `infrastructure/rds.tf` |
| **RDS Instance** | `db.t4g.micro` | `infrastructure/variables.tf` |

### 11.2 Nguồn gốc code

| Phần | Nguồn gốc | Thay đổi |
|------|-----------|----------|
| `infrastructure/` | Copy từ `D:\Infra\TRAVEL-WEB\infrastructure\` | Đổi tên my-ai-platform → travel-web, bỏ Bedrock, thêm Secrets Manager, đổi Nginx → Traefik, gộp frontend+backend SG → app SG |
| `.github/workflows/` | Adapt từ `D:\NT548-DevOps\NT548-DevOps\.github\workflows\` | Django → Next.js, pip → npm, pytest → Jest, Python → TypeScript, dorashop → travel-web, **Account ID 540649423715 → 443014729163**. ⚠️ **File này chỉ để THAM KHẢO — GitLab không đọc. CI/CD thực tế dùng `.gitlab-ci.yml`** |
| `ci-cd/k8s/` | Adapt từ `D:\NT548-DevOps\NT548-DevOps\ci-cd\k8s\` | Deployment → Argo Rollout, thêm HPA, External Secrets, DB Migration Job, Traefik IngressRoute |
| `ci-cd/argocd/` | Adapt từ `D:\NT548-DevOps\NT548-DevOps\ci-cd\argocd\` | Đổi tên, URL, thêm canary rollout annotations |
| `monitoring/` | Adapt từ `D:\Infra\TRAVEL-WEB\monitoring\` | Thêm Loki, OTel Collector, cập nhật scrape targets cho Next.js |
| `scripts/` | Adapt từ `D:\NT548-DevOps\NT548-DevOps\scripts\` | Cập nhật cho travel-web, thêm deploy-monitoring.sh |
| `ci-cd/docker/Dockerfile` | Viết mới | Multi-stage Next.js standalone build |
| `docker-compose.yml` | Adapt từ `D:\Infra\TRAVEL-WEB\docker-compose.yml` | Thay FastAPI+Streamlit bằng Next.js, thêm Loki+Promtail |

---

## 12. LƯU Ý KHI SỬA CODE

1. **Không sửa trực tiếp trong `web/TRAVEL-WEB/`** — đó là submodule. Sửa ở repo TRAVEL-WEB riêng rồi cập nhật submodule.

2. **Khi thay đổi K8s manifests**: chạy `./scripts/validate-kustomize.sh` để validate trước khi commit.

3. **Khi thay đổi Terraform**: luôn chạy `terraform plan` trước `apply`. Không bao giờ `terraform destroy` trên production.

4. **ECR Account ID**: AWS Account ID `443014729163` (nguồn: `D:\Infra\TRAVEL-WEB\infrastructure\SETUP_AWS_PERMISSIONS.md`). Đã được cập nhật trong:
   - `ci-cd/k8s/base/kustomization.yaml` ✅
   - `ci-cd/k8s/overlays/*/kustomization.yaml` ✅
   - `ci-cd/k8s/base/external-secret.yaml` ✅
   - `.github/workflows/ci-cd-pipeline.yml` ✅ (tham khảo, không dùng nữa)
   - `.gitlab-ci.yml` ✅ (đã tạo, dùng Account ID `443014729163`)
   > **LƯU Ý**: Giá trị cũ `540649423715` từ `D:\NT548-DevOps` đã bị thay thế. KHÔNG dùng biến từ NT548-DevOps.

5. **Nền tảng CI/CD**: Đã chuyển sang **GitLab**. Không dùng GitHub Actions nữa.
   - CI/CD chạy trên: `https://gitlab.com/vietdungnguyen2005/NT114-DoAnCN-Devops`
   - File pipeline: `.gitlab-ci.yml` ✅ (đã tạo)
   - Variables: GitLab → Settings → CI/CD → Variables
   - `.github/workflows/` chỉ giữ lại để tham khảo logic

6. **Branch strategy**:
   - `microservice` → Dev (nhánh phát triển chính hiện tại, pipeline CI/CD chạy trên nhánh này)
   - `test` → Dev + Staging
   - `main` → Production (sau khi merge `microservice` → `main` khi ổn định)
   - Feature branches → Merge Request vào `microservice` hoặc `test` (GitLab MR, không phải GitHub PR)

7. **Canary rollout**: Nếu chưa cài Argo Rollouts controller, deployment.yaml sẽ fail. Có thể tạm thời đổi `kind: Rollout` thành `kind: Deployment` và bỏ `strategy.canary` section.

---

## 13. CHI PHÍ ƯỚC TÍNH (Dev/Test)

| Resource | Config | Chi phí/tháng (USD) |
|----------|--------|---------------------|
| EKS Control Plane | 1 cluster | ~$73 |
| EC2 Worker Nodes | 1-3x t3.medium | ~$30-90 |
| NAT Gateway | 1 (single AZ) | ~$45 |
| RDS PostgreSQL | db.t4g.micro, 20GB | ~$12 |
| ECR | 1 repo (~500MB) | ~$0.5 |
| S3 | Static assets + logs | ~$1 |
| CloudWatch | Logs + metrics | ~$10-20 |
| **Tổng** | **Dev/Test** | **~$170-240/tháng** |

> **Tiết kiệm**: Dùng SPOT instances cho worker nodes (tiết kiệm ~70%), tắt cluster ngoài giờ làm việc.

---

## 14. LIÊN HỆ & THAM KHẢO

- **GitLab repo chính (CI/CD)**: `https://gitlab.com/vietdungnguyen2005/NT114-DoAnCN-Devops.git`
- **GitLab submodule TRAVEL-WEB**: `https://gitlab.com/vietdungnguyen2005/TRAVEL-WEB.git`
- **GitHub repo (mirror)**: `https://github.com/vietdungnguyen2005/NT114-DoAnCN-Devops.git`
- **GitHub submodule (mirror)**: `https://github.com/vietdungnguyen2005/TRAVEL-WEB.git`
- **Repo tham khảo CI/CD**: `D:\NT548-DevOps\NT548-DevOps` (Django + DoraShop)
- **Repo tham khảo Infra (nguồn biến hạ tầng)**: `D:\Infra\TRAVEL-WEB` (AI Platform)
- **Terraform AWS EKS Module**: `https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest`
- **Terraform AWS VPC Module**: `https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest`
- **ArgoCD Docs**: `https://argo-cd.readthedocs.io/`
- **Argo Rollouts**: `https://argoproj.github.io/argo-rollouts/`
- **External Secrets Operator**: `https://external-secrets.io/`
- **Traefik on Kubernetes**: `https://doc.traefik.io/traefik/providers/kubernetes-ingress/`
- **GitLab CI/CD Docs**: `https://docs.gitlab.com/ee/ci/`
