bucket         = "optus-ecs-test-state"
key            = "terraform.tfstate"
region         = "ap-southeast-2"
encrypt        = true
dynamodb_table = "terraform-ecs-test-lock-table"
profile        = "Optus"