variable "vpc_cidr" {
  type        = string
  
  description = "CIDR block for the vpc"

}

variable "public_subnet_cidr" {
    description = "CIDR for public subnet"
}

variable "private_subnet_cidr" {
    description = "CIDR for private subnet"
}

variable "env_name" {
    description = "Enviroment name e.g. staging/production"
    
} 

variable "az" {
  description = "Availability Zone"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}