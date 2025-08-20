bucket         = "optus-modules-production-state"
key            = "terraform.tfstate"
region         = "ap-southeast-2"
encrypt        = true
dynamodb_table = "terraform-modules-production-lock-table"
profile        = "Optus"