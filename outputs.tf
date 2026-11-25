output "instance_id" {
  description = "OCID de la máquina virtual creada"
  value       = oci_core_instance.vm.id
}

output "instance_name" {
  description = "Nombre visible de la VM en OCI"
  value       = oci_core_instance.vm.display_name
}

output "instance_state" {
  description = "Estado actual de la VM"
  value       = oci_core_instance.vm.state
}

output "availability_domain" {
  description = "Availability Domain donde se desplegó la VM"
  value       = oci_core_instance.vm.availability_domain
}

output "public_ip" {
  description = "IP pública asignada a la VM"
  value       = oci_core_instance.vm.public_ip
}

output "private_ip" {
  description = "IP privada asignada a la VM dentro de la subnet"
  value       = oci_core_instance.vm.private_ip
}

output "web_url" {
  description = "URL pública HTTP de la aplicación (esperar ~60-90 segundos tras el apply mientras finaliza cloud-init)"
  value       = "http://${oci_core_instance.vm.public_ip}"
}

output "selected_image" {
  description = "Imagen oficial del sistema operativo seleccionada automáticamente"
  value       = data.oci_core_images.os_image.images[0].display_name
}

output "vcn_id" {
  description = "OCID de la VCN detectada a partir de la subnet existente"
  value       = data.oci_core_subnet.existing.vcn_id
}

output "nsg_id" {
  description = "OCID del Network Security Group creado para la VM"
  value       = oci_core_network_security_group.vm_nsg.id
}

output "ssh_command" {
  description = "Comando SSH listo para conectarse a la VM"
  value       = "ssh -i ${replace(var.ssh_public_key_path, ".pub", "")} ubuntu@${oci_core_instance.vm.public_ip}"
}
