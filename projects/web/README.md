# Web Infra

```
terraform workspace select staging
terraform apply -var-file=vars/staging.tfvars
terraform workspace select production
terraform apply -var-file=vars/production.tfvars
```