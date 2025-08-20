bucket         = "optus-db-tactical-lab-state"
key            = "terraform.tfstate"
region         = "ap-southeast-2"
encrypt        = true
dynamodb_table = "terraform-db-tactical-lab-lock-table"
profile        = "Optus"