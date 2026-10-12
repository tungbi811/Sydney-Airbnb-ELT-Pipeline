# Shortcuts for everyday commands. Run `make` to list them.
# Typical day: `make aws-up` -> `make airflow-up` -> unpause the DAG ... `make aws-down` when finished.

TF      := terraform -chdir=terraform
COMPOSE := cd airflow && docker compose
DB_ID   := airbnb-tf
REGION  := ap-southeast-1
DAG     := airbnb_etl
PSQL     = PGPASSWORD=$$($(TF) output -raw postgres_password) psql \
           "host=$$($(TF) output -raw postgres_host) dbname=airbnb user=tung sslmode=require"
CONFIRM := read -p "Type yes to continue: " a && [ "$$a" = yes ]

.DEFAULT_GOAL := help
.PHONY: help aws-up aws-down aws-plan aws-status aws-running aws-env aws-ip aws-upload rds-stop rds-start \
        db-shell db-drop db-reset airflow-up airflow-down backfill dashboard

help: ## List available commands
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-14s %s\n", $$1, $$2}'

# --- AWS infrastructure ---------------------------------------------------

aws-up: ## Create S3 + RDS, write .env, upload CSVs, create Bronze tables (~12 min)
	$(TF) apply -auto-approve
	$(MAKE) aws-env aws-upload
	uv run python -m ingestion.create_tables

aws-down: ## Destroy S3 + RDS: stops all charges, deletes the data (state bucket kept)
	$(TF) destroy

aws-plan: ## Preview infrastructure changes
	$(TF) plan

aws-status: ## Show RDS status and Terraform outputs
	@aws rds describe-db-instances --region $(REGION) --db-instance-identifier $(DB_ID) \
		--query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null || echo "RDS not found (stack is down)"
	@$(TF) output

aws-running: ## List everything in the account that can cost money (all projects, not just Terraform)
	@echo "== RDS instances"; aws rds describe-db-instances --region $(REGION) \
		--query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,DBInstanceClass]' --output text
	@echo "== RDS manual snapshots"; aws rds describe-db-snapshots --region $(REGION) --snapshot-type manual \
		--query 'DBSnapshots[].[DBSnapshotIdentifier,AllocatedStorage]' --output text
	@echo "== EC2 instances"; aws ec2 describe-instances --region $(REGION) \
		--query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType]' --output text
	@echo "== Public IPs"; aws ec2 describe-addresses --region $(REGION) \
		--query 'Addresses[].[PublicIp,NetworkInterfaceOwnerId]' --output text
	@echo "== S3 buckets"; aws s3 ls
	@echo "== Cost this month (USD)"; aws ce get-cost-and-usage \
		--time-period Start=$$(date +%Y-%m-01),End=$$(date -v+1d +%Y-%m-%d) --granularity MONTHLY \
		--metrics UnblendedCost --query 'ResultsByTime[0].Total.UnblendedCost.Amount' --output text

aws-env: ## Write S3_BUCKET, POSTGRES_HOST and POSTGRES_PASSWORD from Terraform into .env
	@[ -n "$$($(TF) output -raw postgres_host 2>/dev/null)" ] || { echo "No Terraform outputs: run make aws-up first"; exit 1; }
	@touch .env
	@for kv in "S3_BUCKET=$$($(TF) output -raw s3_bucket)" \
	           "POSTGRES_HOST=$$($(TF) output -raw postgres_host)" \
	           "POSTGRES_PASSWORD=$$($(TF) output -raw postgres_password)"; do \
		key=$${kv%%=*}; \
		if grep -q "^$$key=" .env; then sed -i '' "s|^$$key=.*|$$kv|" .env; else echo "$$kv" >> .env; fi; \
	done
	@echo ".env updated"

aws-ip: ## Allow your current public IP to reach Postgres (run when your IP changes)
	@ip=$$(curl -s https://checkip.amazonaws.com); \
	echo "my_ip = \"$$ip\"" > terraform/terraform.tfvars; \
	echo "my_ip set to $$ip"
	$(TF) apply -auto-approve -target=aws_vpc_security_group_ingress_rule.postgres

aws-upload: ## Sync local data/ to the S3 bucket
	aws s3 sync data/ s3://$$($(TF) output -raw s3_bucket)/

rds-stop: ## Pause RDS without deleting data (AWS auto-starts it after 7 days)
	aws rds stop-db-instance --region $(REGION) --db-instance-identifier $(DB_ID) --query 'DBInstance.DBInstanceStatus'

rds-start: ## Resume a paused RDS (~5 min)
	aws rds start-db-instance --region $(REGION) --db-instance-identifier $(DB_ID) --query 'DBInstance.DBInstanceStatus'

# --- Database -------------------------------------------------------------
# Rebuilding after a bug: `make db-drop SCHEMA=gold` then clear the dbt tasks in Airflow,
# or `make db-reset` + `make backfill` when snapshot history is wrong (replays from May 2020).

db-shell: ## Open a psql shell on RDS
	@$(PSQL)

db-drop: ## Drop one schema, e.g. `make db-drop SCHEMA=gold` (asks first)
	@[ -n "$(SCHEMA)" ] || { echo "Usage: make db-drop SCHEMA=bronze|silver|gold"; exit 1; }
	@echo "This drops schema $(SCHEMA) and everything in it on $(DB_ID)."
	@$(CONFIRM)
	@$(PSQL) -c "drop schema if exists $(SCHEMA) cascade;"

db-reset: ## Drop Silver and Gold, recreate empty Bronze (asks first)
	@echo "This deletes all data in the airbnb database on $(DB_ID)."
	@$(CONFIRM)
	@$(PSQL) -c "drop schema if exists silver cascade; drop schema if exists gold cascade;"
	uv run python -m ingestion.create_tables

# --- Airflow --------------------------------------------------------------

airflow-up: ## Start Airflow and Metabase (localhost:8080, localhost:3000)
	$(COMPOSE) up -d

airflow-down: ## Stop Airflow and Metabase
	$(COMPOSE) down

backfill: ## Clear all 12 monthly runs so they replay from May 2020 (unpause the DAG after)
	$(COMPOSE) run --rm airflow-cli airflow tasks clear $(DAG) \
		--start-date 2020-05-01 --end-date 2021-04-01 --yes

# --- Dashboard ------------------------------------------------------------

dashboard: ## Rebuild the insights dashboard from Gold
	uv run python -m dashboard.build
