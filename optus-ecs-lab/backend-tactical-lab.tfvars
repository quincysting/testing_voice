bucket         = "optus-ecs-tactical-lab-state"
key            = "terraform.tfstate"
region         = "ap-southeast-2"
encrypt        = true
dynamodb_table = "terraform-ecs-tactical-lab-lock-table"
profile        = "Optus"