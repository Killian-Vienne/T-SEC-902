output "password" {
  value = random_password.password.result
  sensitive = true
}

output "bastion_public_ip" {
  description = "The public IP address for accessing the bastion host"
  value       = module.networking.bastion_public_ip_address
}

output "pfsense_public_ip" {
  description = "The public IP address of the pfSense firewall"
  value       = module.pfsense.public_ip_address
}

output "bastion_private_ip" {
  description = "The private IP address of the bastion host"
  value       = module.bastion.private_ip_address
}

output "glpi_web_private_ip" {
  description = "The private IP address of the GLPI web server"
  value       = module.glpi_web.private_ip_address
}

output "glpi_db_private_ip" {
  description = "The private IP address of the GLPI database server"
  value       = module.glpi_db.private_ip_address
}

output "wazuh_private_ip" {
  description = "The private IP address of the Wazuh server"
  value       = module.wazuh.private_ip_address
}

output "access_instructions" {
  description = "Instructions for accessing the infrastructure"
  value       = <<-EOT
    # Access Instructions

    ## Initial Setup
    1. SSH to the bastion host:
       ssh ${var.admin_username}@${module.networking.bastion_public_ip_address}

    ## pfSense Web Interface
    1. Direct access via public IP:
       https://${module.pfsense.public_ip_address}
    2. OR via SSH tunnel:
       ssh -L 8443:10.0.1.4:443 ${var.admin_username}@${module.networking.bastion_public_ip_address}
       Access the pfSense web interface at: https://localhost:8443    ## GLPI Web Interface
    1. Configure pfSense NAT rules to expose GLPI on port 443
    2. Then access GLPI via: https://${module.pfsense.public_ip_address}
    3. OR via SSH tunnel:
       ssh -L 8080:10.0.1.20:80 ${var.admin_username}@${module.networking.bastion_public_ip_address}
       Access the GLPI web interface at: http://localhost:8080

    ## Wazuh Dashboard
    1. From your local machine, create an SSH tunnel:
       ssh -L 8444:10.0.1.30:443 ${var.admin_username}@${module.networking.bastion_public_ip_address}
    2. Access the Wazuh dashboard at: https://localhost:8444
  EOT
}