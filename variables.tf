variable "project_id" {
  description = "Project ID where resources will be created."
  type        = string
}

variable "disk" {
  description = "Configuration for the persistent disk to be created in the module."
  type = object({
    name                      = string
    description               = optional(string)
    labels                    = optional(map(string), {})
    size_gb                   = optional(number, 10) 
    physical_block_size_bytes = optional(number, 4096)
    disk_type                 = optional(string, "pd-standard")
    access_mode               = optional(string, "READ_WRITE_SINGLE")
    location                  = string  # Zone (e.g., "europe-west1-b") or region (e.g., "europe-west1")
    replica_zones             = optional(set(string)) # Required if location is a region
  })
  default = null

  validation {
    condition = var.disk == null || contains([
      "pd-standard", "pd-balanced", "pd-ssd", "pd-extreme", "hyperdisk-balanced", 
      "hyperdisk-throughput", "hyperdisk-extreme"
    ], var.disk.disk_type)
    error_message = "The disk_type must be one of: pd-standard, pd-balanced, pd-ssd, pd-extreme, hyperdisk-balanced, hyperdisk-throughput, hyperdisk-extreme."
  }
}

variable "replication_target" {
  description = "Configuration for the replication target location in another region."
  type = object({
    location = string  # Must be a zone in a different region
  })
  default = null
}

variable "enable_regional_disk_replication" {
  description = "Whether to enable replication of regional disks using snapshot/restore method."
  type        = bool
  default     = false
}

variable "storage_classes" {
  description = "Configuration for Kubernetes StorageClasses."
  type = map(object({
    name                   = string
    is_default             = optional(bool, false)
    annotations            = optional(map(string), {})
    labels                 = optional(map(string), {})
    reclaim_policy         = optional(string, "Delete")
    volume_binding_mode    = optional(string, "WaitForFirstConsumer")
    allow_volume_expansion = optional(bool, true)
    disk_type              = optional(string, "pd-standard")
    parameters             = optional(map(string), {})
    use_module_disk        = optional(bool, false) # Set to true to use the disk created by this module
  }))
  default = {}

  validation {
    condition = length([
      for k, v in var.storage_classes : 
      v if !contains([
        "pd-standard", "pd-balanced", "pd-ssd", "pd-extreme", "hyperdisk-balanced", 
        "hyperdisk-throughput", "hyperdisk-extreme"
      ], v.disk_type)
    ]) == 0
    error_message = "All storage classes must have a valid disk_type: pd-standard, pd-balanced, pd-ssd, pd-extreme, hyperdisk-balanced, hyperdisk-throughput, hyperdisk-extreme."
  }
}

variable "persistent_volumes" {
  description = "Configuration for Kubernetes PersistentVolumes."
  type = map(object({
    name               = string
    annotations        = optional(map(string), {})
    labels             = optional(map(string), {})
    size_gb            = number
    access_mode        = optional(string, "ReadWriteOnce")
    storage_class_name = string
    reclaim_policy     = optional(string, "Retain")
    volume_mode        = optional(string, "Filesystem")
    use_module_disk    = optional(bool, false)  # Set to true to use the disk created by this module
    disk_ref           = optional(string)       # Only needed for referencing external disks
    disk_name          = optional(string)       # Only needed for referencing external disks by name
    fs_type            = optional(string, "ext4")
    read_only          = optional(bool, false)
  }))
  default = {}
}

variable "persistent_volume_claims" {
  description = "Configuration for Kubernetes PersistentVolumeClaims."
  type = map(object({
    name               = string
    namespace          = string
    annotations        = optional(map(string), {})
    labels             = optional(map(string), {})
    access_mode        = optional(string, "ReadWriteOnce")
    storage_class_name = string
    pv_ref             = optional(string) # Optional to allow dynamic provisioning
    size_gb            = number
  }))
  default = {}
}
