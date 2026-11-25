variable "tenancy_ocid" {
  description = "OCID del Tenancy de OCI (se obtiene en la consola de OCI -> Tenancy)"
  type        = string
}

variable "user_ocid" {
  description = "OCID del usuario de OCI (se obtiene en Perfil -> My profile)"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint de la API Key configurada en tu usuario de OCI"
  type        = string
}

variable "private_key_path" {
  description = "Ruta al archivo .pem de la API Key privada cargada en OCI Cloud Shell (o local)"
  type        = string
  default     = "./keys/oci_api_key.pem"
}

variable "private_key_password" {
  description = "Passphrase de la llave privada de OCI (dejar null si no tiene contraseña)"
  type        = string
  default     = null
  sensitive   = true
}

variable "region" {
  description = "Identificador de la región de OCI donde se desplegará la VM (ej. sa-saopaulo-1, us-ashburn-1)"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID del Compartment donde se crearán la VM y el Network Security Group (NSG)"
  type        = string
}

variable "subnet_ocid" {
  description = "OCID de la Subnet pública existente donde se conectará la VM"
  type        = string
}

variable "vm_display_name" {
  description = "Nombre visible de la máquina virtual en la consola de OCI"
  type        = string
  default     = "oci-vm-automatic"
}

variable "vm_shape" {
  description = "Shape de cómputo en OCI (ej. VM.Standard.E2.1.Micro, VM.Standard.A1.Flex, VM.Standard.E4.Flex)"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "vm_ocpus" {
  description = "Número de OCPUs (solo se aplica cuando vm_shape termina en .Flex)"
  type        = number
  default     = 1
}

variable "vm_memory_in_gbs" {
  description = "Memoria RAM en GB (solo se aplica cuando vm_shape termina en .Flex)"
  type        = number
  default     = 2
}

variable "boot_volume_size_in_gbs" {
  description = "Tamaño del Boot Volume en GB (mínimo configurable en OCI: 50 GB)"
  type        = number
  default     = 50
}

variable "os_name" {
  description = "Nombre del sistema operativo en el catálogo oficial de imágenes de OCI"
  type        = string
  default     = "Canonical Ubuntu"
}

variable "os_version" {
  description = "Versión del sistema operativo en OCI Images"
  type        = string
  default     = "24.04"
}

variable "image_display_name_regex" {
  description = "Expresión regular para elegir la imagen estándar oficial del SO (x86_64 o aarch64)"
  type        = string
  default     = "^Canonical-Ubuntu-24\\.04(-aarch64)?-[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}-[0-9]+$"
}

variable "ssh_public_key_path" {
  description = "Ruta a la llave SSH pública que se inyectará en el usuario ubuntu de la VM"
  type        = string
  default     = "./keys/oci_vm_key.pub"
}

variable "allowed_tcp_ports" {
  description = "Lista de puertos TCP de entrada abiertos en el NSG dedicado a la VM"
  type        = list(number)
  default     = [22, 80, 443]
}

variable "ingress_cidr" {
  description = "CIDR permitido para el tráfico entrante (0.0.0.0/0 permite acceso desde internet)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "enable_cloud_init" {
  description = "Activa el script cloud-init al primer arranque para instalar Nginx, clonar la web y abrir iptables"
  type        = bool
  default     = true
}

variable "git_repo_url" {
  description = "URL HTTPS del repositorio estático de GitHub que será servido por Nginx"
  type        = string
  default     = "https://github.com/adanbeltran/ecored-estatica.git"
}

variable "web_root_dir" {
  description = "Ruta dentro de la VM donde se clonará y publicará el sitio web estático"
  type        = string
  default     = "/var/www/ecored-estatica"
}
