export GOOGLE_APPLICATION_CREDENTIALS=~/iwashi-terraform-key.json
terraform init
terraform plan
terraform apply

cd envs/prod
terraform init
terraform apply -var-file=terraform.tfvars
