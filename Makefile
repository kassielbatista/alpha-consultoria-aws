# Makefile for alpha_k_infra
# Handles Terraform bootstrap, plan, and apply with dependency validation

.PHONY: help bootstrap plan apply apply-plan destroy destroy-all clean init \
	check-bootstrap check-aws setup configure-kubectl install-metrics-server \
	install-lb-controller outputs status

# Configuration
AWS_REGION ?= us-east-1
TF_STATE_BUCKET := alpha-k-tfstate
TF_DIR := terraform
BOOTSTRAP_DIR := terraform/bootstrap

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-22s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Quick Start:"
	@echo "  make setup        # Deploy infrastructure + install LB controller"
	@echo ""
	@echo "Step-by-Step:"
	@echo "  make apply                 # 1. Deploy infrastructure"
	@echo "  make install-lb-controller # 2. Install AWS Load Balancer Controller"
	@echo ""
	@echo "Other:"
	@echo "  make plan         # Preview infrastructure changes"
	@echo "  make destroy      # Tear down everything"

setup: apply install-lb-controller ## Deploy infrastructure and install LB controller
	@echo ""
	@echo "$(GREEN)Infrastructure ready!$(NC)"

check-aws: ## Verify AWS credentials are configured
	@echo "$(YELLOW)Checking AWS credentials...$(NC)"
	@aws sts get-caller-identity > /dev/null 2>&1 || \
		(echo "$(RED)Error: AWS credentials not configured. Run 'aws configure' first.$(NC)" && exit 1)
	@echo "$(GREEN)AWS credentials OK$(NC)"

check-bootstrap: check-aws ## Check if bootstrap has been run
	@echo "$(YELLOW)Checking if state bucket exists...$(NC)"
	@if aws s3api head-bucket --bucket $(TF_STATE_BUCKET) 2>/dev/null; then \
		echo "$(GREEN)State bucket exists$(NC)"; \
	else \
		echo "$(YELLOW)State bucket not found. Running bootstrap...$(NC)"; \
		$(MAKE) bootstrap; \
	fi

bootstrap: check-aws ## Create S3 bucket for Terraform state
	@echo "$(GREEN)Bootstrapping Terraform state backend...$(NC)"
	@cd $(BOOTSTRAP_DIR) && \
		terraform init && \
		terraform apply -auto-approve
	@echo "$(GREEN)Bootstrap complete!$(NC)"

init: check-bootstrap ## Initialize Terraform (runs after bootstrap check)
	@echo "$(YELLOW)Initializing Terraform...$(NC)"
	@cd $(TF_DIR) && terraform init
	@echo "$(GREEN)Terraform initialized$(NC)"

plan: init ## Run Terraform plan (auto-bootstraps if needed)
	@echo "$(GREEN)Running Terraform plan...$(NC)"
	@cd $(TF_DIR) && terraform plan -out=tfplan
	@echo "$(GREEN)Plan complete! Review above and run 'make apply' to proceed.$(NC)"

apply: init ## Run Terraform apply (auto-bootstraps if needed)
	@echo "$(GREEN)Running Terraform apply...$(NC)"
	@cd $(TF_DIR) && terraform apply -auto-approve
	@echo ""
	@echo "$(GREEN)=====================================$(NC)"
	@echo "$(GREEN)Infrastructure deployed successfully!$(NC)"
	@echo "$(GREEN)=====================================$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Configure kubectl:"
	@echo "     $$(cd $(TF_DIR) && terraform output -raw configure_kubectl)"
	@echo ""
	@echo "  2. Install AWS Load Balancer Controller:"
	@echo "     make install-lb-controller"

apply-plan: init ## Apply a previously created plan
	@echo "$(GREEN)Applying Terraform plan...$(NC)"
	@cd $(TF_DIR) && terraform apply tfplan
	@echo "$(GREEN)Apply complete!$(NC)"

destroy: check-aws ## Destroy all infrastructure (requires confirmation)
	@echo "$(RED)WARNING: This will destroy all infrastructure!$(NC)"
	@read -p "Are you sure? Type 'yes' to confirm: " confirm && \
		[ "$$confirm" = "yes" ] || (echo "Aborted." && exit 1)
	@echo "$(YELLOW)Destroying Terraform infrastructure...$(NC)"
	@cd $(TF_DIR) && terraform destroy -auto-approve
	@echo "$(GREEN)Infrastructure destroyed$(NC)"

destroy-all: destroy ## Destroy infrastructure AND bootstrap resources
	@echo "$(RED)WARNING: This will also destroy the state bucket!$(NC)"
	@read -p "Are you sure? Type 'destroy-bootstrap' to confirm: " confirm && \
		[ "$$confirm" = "destroy-bootstrap" ] || (echo "Aborted." && exit 1)
	@cd $(BOOTSTRAP_DIR) && terraform destroy -auto-approve
	@echo "$(GREEN)All resources destroyed$(NC)"

clean: ## Clean up local Terraform files
	@echo "$(YELLOW)Cleaning up local Terraform files...$(NC)"
	@rm -rf $(TF_DIR)/.terraform
	@rm -rf $(TF_DIR)/tfplan
	@rm -rf $(TF_DIR)/.terraform.lock.hcl
	@rm -rf $(BOOTSTRAP_DIR)/.terraform
	@rm -rf $(BOOTSTRAP_DIR)/.terraform.lock.hcl
	@echo "$(GREEN)Cleanup complete$(NC)"

# ==================== Kubernetes Targets ====================

configure-kubectl: check-aws ## Configure kubectl to connect to EKS cluster
	@echo "$(GREEN)Configuring kubectl...$(NC)"
	@CLUSTER_NAME=$$(cd $(TF_DIR) && terraform output -raw cluster_name 2>/dev/null) && \
	if [ -z "$$CLUSTER_NAME" ]; then \
		echo "$(RED)Error: Cluster not found. Run 'make apply' first.$(NC)"; \
		exit 1; \
	fi && \
	aws eks update-kubeconfig --region $(AWS_REGION) --name $$CLUSTER_NAME
	@echo "$(GREEN)kubectl configured!$(NC)"

install-metrics-server: configure-kubectl ## Install Metrics Server (required for HPA)
	@echo "$(GREEN)Installing Metrics Server...$(NC)"
	@kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	@echo "$(YELLOW)Waiting for Metrics Server...$(NC)"
	@kubectl wait --for=condition=available --timeout=120s deployment/metrics-server -n kube-system
	@echo "$(GREEN)Metrics Server installed!$(NC)"

install-lb-controller: configure-kubectl install-metrics-server ## Install AWS Load Balancer Controller
	@echo "$(GREEN)Installing AWS Load Balancer Controller...$(NC)"
	@kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
	@echo "$(YELLOW)Waiting for cert-manager...$(NC)"
	@kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
	@kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager
	@helm repo add eks https://aws.github.io/eks-charts 2>/dev/null || true
	@helm repo update
	@LB_ROLE_ARN=$$(cd $(TF_DIR) && terraform output -raw lb_controller_role_arn) && \
	CLUSTER_NAME=$$(cd $(TF_DIR) && terraform output -raw cluster_name) && \
	VPC_ID=$$(aws eks describe-cluster --region $(AWS_REGION) --name $$CLUSTER_NAME --query "cluster.resourcesVpcConfig.vpcId" --output text) && \
	helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
		-n kube-system \
		--set clusterName=$$CLUSTER_NAME \
		--set serviceAccount.create=true \
		--set serviceAccount.name=aws-load-balancer-controller \
		--set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$$LB_ROLE_ARN" \
		--set region=$(AWS_REGION) \
		--set vpcId=$$VPC_ID
	@echo "$(YELLOW)Waiting for Load Balancer Controller...$(NC)"
	@kubectl wait --for=condition=available --timeout=300s deployment/aws-load-balancer-controller -n kube-system
	@echo "$(GREEN)AWS Load Balancer Controller installed!$(NC)"

# ==================== Status Targets ====================

status: ## Show infrastructure status
	@echo "$(GREEN)=== Terraform State ===$(NC)"
	@cd $(TF_DIR) && terraform show -no-color 2>/dev/null | head -50 || echo "Not initialized"

outputs: ## Show Terraform outputs
	@cd $(TF_DIR) && terraform output
