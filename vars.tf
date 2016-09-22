variable "nat_ami" {
  "default" = "ami-b7b4fedd"
}

variable "vpn_cidr" {
  "default" = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  "default" = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
  "default" = "10.0.1.0/24"
}

variable "key_name" {
  "default" = "abhishekl"
}
