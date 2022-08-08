
variable "counts" {
 default = 1
 }
variable "region" {
 description = "AWS region for hosting our your network"
 default = "ap-south-1"
}
variable "public_key_path" {
 description = "Enter the path to the SSH Public Key to add to AWS."
 default = "C:/Users/Lenovo580/aws/aws_keys/test_srv_v1.pem"
}
variable "key_name" {
 description = "Key name for SSHing into EC2"
 default = "test_srv_v1"
}
variable "amis" {
 description = "Base AMI to launch the instances"
 default = {
 ap-south-1 = "ami-076e3a557efe1aa9c"
 }
}