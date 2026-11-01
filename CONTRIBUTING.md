# Collaboration guide

## Branches and pull requests

- Keep `main` stable. Use `feature/<short-topic>` branches for changes.
- Open a pull request before merging. Describe purpose, resource changes, affected routes, expected AWS costs and test evidence.
- Prefer small, focused changes and descriptive commit subjects.
- Review Terraform plans before approval; routing changes can cause outages.

## Daily workflow

```powershell
git switch main
git pull --ff-only origin main
git switch -c feature/firewall-routes
# Edit and test files
terraform fmt -recursive
terraform validate
git add .
git diff --cached
git commit -m "Document inspection VPC routes"
git push -u origin feature/firewall-routes
```

Then open a pull request to `main` on GitHub.

## Shared infrastructure and Terraform state

**Never** run `terraform apply` concurrently. Assign one deployment owner and agree on an AWS account/region. Local `terraform.tfstate` is not a collaboration strategy; configure a suitable remote backend with locking before multiple people manage the same deployed stack. Existing deployed state must be migrated with a reviewed backup and a coordinated plan. Never delete or replace state casually. Do not commit it.

## Review checklist

- [ ] `terraform fmt -check -recursive` passes
- [ ] `terraform validate` passes after `terraform init`
- [ ] Plan is reviewed; no unexpected destroy/replace operations
- [ ] Route destinations and targets checked in both directions
- [ ] No credentials, personal account numbers, state files or plans are staged
- [ ] README updated for architecture changes
- [ ] New services and hourly cost impact noted

## Comments and naming

Use English comments describing **why** a route, setting or dependency exists. Avoid comments that merely repeat field names. Match existing module and resource naming patterns. New modules should document inputs, outputs, assumptions and edge cases.
