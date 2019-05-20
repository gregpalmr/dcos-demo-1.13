#variable "dcos_install_mode" {
#  description = "specifies which type of command to execute. Options: install or upgrade"
#  default     = "install"
#}
# Used to determine your public IP for forwarding rules
data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

provider "aws" {
  # version = "1.43.2"
  region = "us-east-1"
}

resource "random_id" "cluster_name" {
  prefix      = "mycluster-"
  byte_length = 2
}

module "dcos" {
  source = "dcos-terraform/dcos/aws"

  #  dcos_instance_os    = "coreos_1855.5.0"
  dcos_instance_os             = "centos_7.5"
  cluster_name                 = "${random_id.cluster_name.hex}"
  dcos_version                 = "1.13.0"
  ssh_public_key_file          = "~/.ssh/id_rsa-terraform.pub"
  admin_ips                    = ["0.0.0.0/0"]
  num_masters                  = "1"
  num_private_agents           = "11"
  num_public_agents            = "1"
  bootstrap_instance_type      = "t2.medium"
  public_agents_instance_type  = "t3.xlarge"
  private_agents_instance_type = "t3.2xlarge"
  masters_instance_type        = "t3.2xlarge"
  availability_zones           = ["us-east-1a", "us-east-1b", "us-east-1c"]

  #dcos_variant = "open"
  subnet_range              = "172.16.0.0/16"
  dcos_variant              = "ee"
  dcos_license_key_contents = "${file("~/scripts/license.txt")}"

  #dcos_install_mode = "${var.dcos_install_mode}"
  #dcos_resolvers = ["169.254.169.253"]
  tags = {
    owner = "Firstname Lastname"

    expiration = "8h"
  }

  dcos_overlay_network = <<EOF
  # YAML
      vtep_subnet: 44.128.0.0/20
      vtep_mac_oui: 70:B3:D5:00:00:00
      overlays:
        - name: dcos
          subnet: 12.0.0.0/8
          prefix: 26
        - name: dev
          subnet: 9.1.0.0/16
          prefix: 24
        - name: qa
          subnet: 9.2.0.0/16
          prefix: 24
        - name: prod
          subnet: 9.3.0.0/16
          prefix: 24
  EOF

  #  dcos_resolvers = <<EOF
  #  # YAML
  #    - "169.254.169.253"
  #  EOF

  public_agents_additional_ports = ["6000", "6001", "6002", "6003", "6445", "6444", "6443", "7443", "8080", "8085", "10001", "10002", "10003", "10004", "10005", "10006", "10080", "10108", "11080", "12080", "13080", "14080", "3000", "9090", "9093", "9091", "9092","6090", "30001", "30443", "30080"]
}

output "masters-ips" {
  value = "${module.dcos.masters-ips}"
}

output "cluster-address" {
  value = "${module.dcos.masters-loadbalancer}"
}

output "public-agents-loadbalancer" {
  value = "${module.dcos.public-agents-loadbalancer}"
}

