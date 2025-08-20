bucket         = "optus-modules-test-state"
key            = "terraform.tfstate"
region         = "ap-southeast-2"
encrypt        = true
dynamodb_table = "terraform-modules-test-lock-table"
profile        = "Optus"