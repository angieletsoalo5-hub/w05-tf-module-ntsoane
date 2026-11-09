# w05-tf-module-ntsoane

**Week 5 – Terraform module + usage example** · Angie Ntsoane · Cloud Track · Region `us-east-1`

```
w05-tf-module-ntsoane/
├── README.md                      <- this file
├── .gitignore
├── modules/
│   └── sandbox/                   <- the reusable module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── examples/
│   └── basic/                     <- a root config that calls the module
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars.example
│       └── .terraform.lock.hcl    <- provider version lock (safe to commit)
└── docs/
    └── screenshots/               <- add plan/apply/destroy screenshots here
```

---

## Purpose

In Week 4 I built a flat Terraform stack (one EC2 VM plus one private, encrypted S3 bucket). This week I turned that stack into a **reusable module** called `sandbox` and added an **example** that calls it. That means:

- the same stack can be deployed again (for another week, person or environment) just by calling the module with different inputs, without copying code
- nothing is hardcoded: region, profile, instance type, names and tags are all variables with safe defaults and validation
- every resource carries the required tags `module = "sandbox"` and `environment = "lab"`
- the work went through a Git workflow (feature branch, small commits, then a PR-style merge into `main`)

What the stack does is **the same as Week 4**: the same resources, the same AMI filter (Amazon Linux 2023), the same `t3.micro` default, the same S3 hardening, and the same provider versions (`aws ~> 5.0`, `random ~> 3.6`, Terraform `>= 1.5.0`).

---

## Tuesday planning

### Week 4 resources wrapped into the module

| # | Week 4 resource | What it is | Change in the module |
|---|---|---|---|
| 1 | `data.aws_ami.al2023` | Looks up the latest Amazon Linux 2023 AMI | Same filter. Skipped if `ami_id` is supplied |
| 2 | `aws_instance.vm` | EC2 VM (`t3.micro`) | `Name` tag now built from `project_name`, type validated |
| 3 | `random_id.suffix` | 4-byte random suffix for the bucket name | Unchanged |
| 4 | `aws_s3_bucket.private` | S3 bucket | Prefix validated, `force_destroy` input added (default `false`), `Name` tag |
| 5 | `aws_s3_bucket_public_access_block.private` | Blocks all public access | Unchanged |
| 6 | `aws_s3_bucket_server_side_encryption_configuration.private` | AES-256 encryption at rest | Unchanged |

The `provider "aws"` block moved **out** of the module and into `examples/basic`. Modules should not configure providers; the caller does that.

### Inputs/outputs sketch

| Direction | Name | Type | Default | Notes |
|---|---|---|---|---|
| input | `project_name` | string | `w05-sandbox` | Used in `Name` tags |
| input | `environment` | string | `lab` | `lab`/`dev`/`test` only |
| input | `instance_type` | string | `t3.micro` | Small types only (cost control) |
| input | `ami_id` | string | `null` | null = latest AL2023 |
| input | `bucket_prefix` | string | `w05-tf-module-ntsoane` | Random suffix appended |
| input | `force_destroy` | bool | `false` | Safety: keep false |
| input | `owner` / `week` / `purpose` | string | see module README | Tags |
| input | `extra_tags` | map(string) | `{}` | Cannot override required tags |
| output | `instance_id` | string | – | EC2 ID |
| output | `instance_public_ip` | string | – | EC2 public IP |
| output | `instance_ami` | string | – | AMI used |
| output | `bucket_name` | string | – | S3 bucket name |
| output | `bucket_arn` | string | – | S3 bucket ARN |
| output | `tags` | map(string) | – | Tags applied |

---

## How to use the example

**Prerequisites:** Terraform >= 1.5.0, AWS CLI v2, and an AWS CLI profile called `sandbox` (`aws configure --profile sandbox`). No access keys go into this repo.

All commands are for **Windows PowerShell**. Run them from the repo folder.

```powershell
# 1. Go into the example folder
cd .\examples\basic

# 2. Create your own variables file from the template (the real file is git-ignored)
Copy-Item terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars        # change owner and bucket_prefix to your values

# 3. Download providers and link the local module
terraform init

# 4. Check formatting and syntax
terraform fmt -check -recursive ..\..
terraform validate
```

Then follow [RUN_COMMANDS](#run_commands-plan--apply--destroy--screenshots) below for plan, apply and destroy.

---

## Inputs/outputs

The example passes these inputs to the module (set them in `terraform.tfvars`):

| Name | Default | Description |
|---|---|---|
| `aws_region` | `us-east-1` | Region for the AWS provider (example only) |
| `aws_profile` | `sandbox` | Local AWS CLI profile (example only) |
| `project_name` | `w05-sandbox` | Name prefix for `Name` tags |
| `environment` | `lab` | Environment tag |
| `instance_type` | `t3.micro` | EC2 type |
| `bucket_prefix` | `w05-tf-module-ntsoane` | S3 bucket name prefix |
| `owner` | `angie-ntsoane` | Owner tag |
| `week` | `w05` | Week tag |
| `purpose` | `terraform-module-practice` | Purpose tag |

The example prints these outputs after apply: `instance_id`, `instance_public_ip`, `bucket_name`, `bucket_arn`.

The full module reference (all inputs, types, validation rules and outputs) is in [`modules/sandbox/README.md`](modules/sandbox/README.md).

---

## State notes

**This week: local backend.** `examples/basic` uses `backend "local" {}`, so state is saved to `terraform.tfstate` on my own laptop. That's fine for this lab because:

- I'm the only person running Terraform against this sandbox, so nobody else needs to read the state or could change it at the same time
- the resources are short-lived (create, check, destroy in one session)
- `.gitignore` keeps `*.tfstate*` out of Git, so state (which can hold sensitive values) is never committed

**Why a team needs remote state** (for example S3 with native lockfile or DynamoDB locking, or HCP Terraform):

- **Locking:** only one `apply` can run at a time. Without a lock, two people applying at once can corrupt state or create duplicate resources.
- **Shared source of truth:** everyone plans against the same, latest state instead of out-of-date copies on different laptops.
- **Encryption and versioning:** the state bucket is encrypted at rest, and object versioning lets you roll back to an earlier state if it gets corrupted or deleted by mistake.
- **Access control:** IAM policies decide who can read or write state. That matters because state can contain secrets and resource details.

---

## Cost & clean-up

- `t3.micro` and a small S3 bucket cost little, and may be covered by the AWS Free Tier depending on your account. The EC2 instance is billed **for every hour it runs**, so destroy it when you're done.
- Always run `terraform destroy` at the end of the session (see below), then check the EC2 and S3 consoles in `us-east-1` to make sure nothing is left.
- `force_destroy` is `false`, so destroy **fails if the bucket still has objects**. Empty the bucket first (`aws s3 rm s3://<bucket_name> --recursive --profile sandbox`). This is a deliberate safety net.
- Keep an AWS Budget alert on the account.

---

## Security notes

- **No credentials in code.** The provider uses a local AWS CLI profile (`aws_profile`). Keys stay in `%USERPROFILE%\.aws\`.
- `.gitignore` excludes `.terraform/`, `*.tfstate*`, `*.tfvars` (but keeps `*.tfvars.example`), saved plans and crash logs.
- `terraform.tfvars.example` contains **placeholder values only**: no secrets and no account IDs.
- The S3 bucket blocks **all** public access and encrypts objects with AES-256 (SSE-S3).
- Inputs are validated (allowed instance types, bucket naming rules, environment names) so mistakes are caught before anything is created.
- Required tags (`module`, `environment`) are merged last, so `extra_tags` can't overwrite them.
- **Secret scan:** see the Verification log below. Run Gitleaks yourself before submitting:
  ```powershell
  gitleaks detect --source . -v      # expect: "no leaks found"
  ```

---

## Verification log (what was and wasn't run)

| Check | Result |
|---|---|
| `terraform fmt -check -recursive` (Terraform v1.9.8) | ✅ Passed, no formatting changes needed |
| `terraform init -backend=false` + `terraform validate` in `examples/basic` | ✅ `Success! The configuration is valid.` |
| Variable validation test (`instance_type = "m5.large"`) | ✅ Rejected with `Invalid value for variable` |
| Required-tag precedence test (`extra_tags = { module = "x" }`) | ✅ `module` stayed `"sandbox"` |
| Gitleaks | ⚠️ **Not run.** The Gitleaks binary download from GitHub failed (HTTP 504) in the build environment. A fallback pattern scan of all commits (AWS key IDs, secret/token/password assignments, private keys, 12-digit account IDs) found **no secrets**. The only hits were provider checksum hashes in `.terraform.lock.hcl`. Run the Gitleaks command above before submitting. |
| `terraform plan` / `apply` / `destroy` | ❌ **Not run.** No AWS credentials in the build environment. Run them yourself using the commands below. |

---

## RUN_COMMANDS: plan / apply / destroy + screenshots

Run in **PowerShell** from `examples\basic`, after `terraform init`:

```powershell
# Confirm you are using the right AWS account/profile
aws sts get-caller-identity --profile sandbox

# PLAN: preview what will be created (expect "Plan: 5 to add, 0 to change, 0 to destroy.")
terraform plan -out=tfplan
#   Screenshot -> docs\screenshots\plan.png

# APPLY: create the resources from the saved plan
terraform apply tfplan
terraform output
#   Screenshot -> docs\screenshots\apply.png

# Check in the console (us-east-1):
#   EC2 > Instances: "w05-sandbox-vm" with tags module=sandbox, environment=lab
#     Screenshot -> docs\screenshots\ec2-instance.png
#   S3 > bucket "w05-tf-module-...-xxxxxxxx" > Properties/Permissions/Tags
#     Screenshot -> docs\screenshots\s3-bucket.png

# DESTROY: delete everything (type "yes" when asked)
terraform destroy
#   Screenshot -> docs\screenshots\destroy.png   (expect "Destroy complete! Resources: 5 destroyed.")

# Remove the saved plan file (it is git-ignored, but tidy up anyway)
Remove-Item tfplan
```

Commit the screenshots afterwards:

```powershell
cd ..\..
git add docs/screenshots/*.png
git commit -m "docs: add plan/apply/destroy screenshots"
```

---

## Git workflow

1. `main`: scaffold commit (layout + `.gitignore`)
2. `feature/sandbox-module` branch: module, then example, then docs (small logical commits)
3. Merged into `main` with `git merge --no-ff`. The merge commit message contains the PR-style description (summary, changes, testing).

> A real GitHub Pull Request could not be opened because this repo has no remote yet. To do it for real: create an empty GitHub repo, then `git remote add origin <url>`, `git push -u origin main feature/sandbox-module`, and open a PR from `feature/sandbox-module` (the history already shows the merge).

---

## Link to commit hash

Submission commit (merge of `feature/sandbox-module` into `main`): **`97bd0f47d616f191059ab4a52f5413935b4d4b60`** (short: `97bd0f4`)

> This is the hash of the commit at submission time. A commit can't contain its own hash, so this README is updated in one small follow-up commit that points to the merge commit above. Check it with `git log --oneline --graph`. If you push to GitHub, the link will be `https://github.com/<your-username>/w05-tf-module-ntsoane/commit/<hash>`.
