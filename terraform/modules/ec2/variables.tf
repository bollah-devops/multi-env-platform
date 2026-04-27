variable "ami_id" {
    description = "AMI ID for EC2 instances"
    default = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS, us-east-1
}

variable "instance_type" {
    description = "EC2 instance type"
    default = "t2.micro"
}

variable "public_subnet_id" {
    type = string
}

variable "key_name" {
    type = string
}

variable "app_sg_id" { 
    type = string 
}

variable "db_sg_id" { 
    type = string 
}

variable "env_name" { 
    type = string 
}