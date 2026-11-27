# Obtener los Availability Domains de la región configurada
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Consultar la Subnet existente para obtener su VCN padre y validar que permita IP pública
data "oci_core_subnet" "existing" {
  subnet_id = var.subnet_ocid
}

# Consultar la imagen oficial más reciente del SO compatible con el Shape elegido
data "oci_core_images" "os_image" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.os_name
  operating_system_version = var.os_version
  shape                    = var.vm_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

  filter {
    name   = "display_name"
    values = [var.image_display_name_regex]
    regex  = true
  }
}

locals {
  # Si la subnet es de un AD específico, despliega ahí; si es regional, elige el primer AD disponible
  availability_domain = coalesce(
    try(length(data.oci_core_subnet.existing.availability_domain) > 0 ? data.oci_core_subnet.existing.availability_domain : null, null),
    data.oci_identity_availability_domains.ads.availability_domains[0].name
  )

  # Garantizar saltos de línea Unix (LF) antes de codificar el script cloud-init en base64
  cloud_init_script = replace(
    templatefile("${path.module}/scripts/cloud-init.sh.tftpl", {
      repo_url = var.git_repo_url
      web_root = var.web_root_dir
    }),
    "\r\n",
    "\n"
  )

  instance_metadata = merge(
    {
      ssh_authorized_keys = trimspace(file(pathexpand(var.ssh_public_key_path)))
    },
    var.enable_cloud_init ? {
      user_data = base64encode(local.cloud_init_script)
    } : {}
  )
}

# Network Security Group (NSG) exclusivo para esta VM (no modifica Security Lists existentes)
resource "oci_core_network_security_group" "vm_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_subnet.existing.vcn_id
  display_name   = "${var.vm_display_name}-nsg"
}

# Reglas de entrada (Ingress TCP) para los puertos configurados (22, 80, 443)
resource "oci_core_network_security_group_security_rule" "ingress_tcp" {
  for_each = toset([for p in var.allowed_tcp_ports : tostring(p)])

  network_security_group_id = oci_core_network_security_group.vm_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = var.ingress_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = false
  description               = "Permitir tráfico TCP entrante en el puerto ${each.value}"

  tcp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
}

# Regla de salida (Egress) permitiendo todo el tráfico saliente (requerido para apt-get y git clone)
resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.vm_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
  description               = "Permitir todo el tráfico saliente"
}

# Instancia de Máquina Virtual (Compute Instance)
resource "oci_core_instance" "vm" {
  availability_domain = local.availability_domain
  fault_domain        = var.fault_domain
  compartment_id      = var.compartment_ocid
  display_name        = var.vm_display_name
  shape               = var.vm_shape

  dynamic "shape_config" {
    for_each = endswith(var.vm_shape, ".Flex") ? [1] : []
    content {
      ocpus         = var.vm_ocpus
      memory_in_gbs = var.vm_memory_in_gbs
    }
  }

  create_vnic_details {
    subnet_id        = var.subnet_ocid
    assign_public_ip = true
    display_name     = "${var.vm_display_name}-vnic"
    nsg_ids          = [oci_core_network_security_group.vm_nsg.id]
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.os_image.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  metadata = local.instance_metadata

  # Elimina también el boot volume cuando se ejecute `terraform destroy`
  preserve_boot_volume = false

  lifecycle {
    precondition {
      condition     = !data.oci_core_subnet.existing.prohibit_public_ip_on_vnic
      error_message = "La subnet especificada es privada (prohibit_public_ip_on_vnic = true) y no permite asignar una IP pública."
    }

    precondition {
      condition     = length(data.oci_core_images.os_image.images) > 0
      error_message = "No se encontró ninguna imagen compatible para el SO y Shape especificados."
    }
  }
}
