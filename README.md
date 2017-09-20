# aws-tfstate-module

Work in progress .....

Creates the s3 resources needed to store the terraform state with locking.  Including a seperate user, policy and IAM creds, using keybase to avoid storing raw secret.

## Use the module

module "tfstate" {
  source = "git@github.com:domg123/aws-tfstate-module.git"
  bucket-name   = "some-bucket-name"
}

output "tfstate-accesskey" {
   value = "${module.tfstate.access_key}"
}

output "tfstate-secret" {
   value = "${module.tfstate.secret_key}"
   sensitive = true
}

## Inputs

| variable  |  default  | required |  description    |
|-----------|-----------|---------|--------|
|  bucket-name   |      |  Yes  |   name of the bucket (and other resources )| 
|  keybase-id   |      |  Yes  |   keybase id for PGP key to encrypt user secret | 


## Setting the backend

There is a chicken and egg issue here, as you can't use the backend, until the resources in the modeule are created, so, after applying the above, add in backend config..

terraform {
  backend "s3" {
    bucket   = "my-unique-tfstate-bucket-name"
    key    = "main.tfstate"
    region = "us-east-1"
    dynamodb_table = "my-unique-tfstate-bucket-name-ddb-table"
    region     = "us-east-1"
  }
}

In my case, tfstate_access_key and tfstate_secret_key are set as environment variables.  You can't use interpolate syntax to add the access/secret key directly, so the init command is ...

terraform init -backend-config="secret_key=${tfstate_secret_key}" -backend-config="secret_key=${tfstate_access_key}"
