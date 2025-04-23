## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 6.31.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.36.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_disk.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_disk.replication_target](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_disk_async_replication.replication](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk_async_replication) | resource |
| [google_compute_region_disk.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_disk) | resource |
| [google_compute_snapshot.regional_disk_snapshot](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_snapshot) | resource |
| [kubernetes_persistent_volume_claim_v1.main](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [kubernetes_persistent_volume_v1.main](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_v1) | resource |
| [kubernetes_storage_class_v1.main](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_disk"></a> [disk](#input\_disk) | Configuration for the persistent disk to be created in the module. | <pre>object({<br>    name                      = string<br>    description               = optional(string)<br>    labels                    = optional(map(string), {})<br>    size_gb                   = optional(number, 10) <br>    physical_block_size_bytes = optional(number, 4096)<br>    disk_type                 = optional(string, "pd-standard")<br>    access_mode               = optional(string, "READ_WRITE_SINGLE")<br>    location                  = string  # Zone (e.g., "europe-west1-b") or region (e.g., "europe-west1")<br>    replica_zones             = optional(set(string)) # Required if location is a region<br>  })</pre> | `null` | no |
| <a name="input_enable_regional_disk_replication"></a> [enable\_regional\_disk\_replication](#input\_enable\_regional\_disk\_replication) | Whether to enable replication of regional disks using snapshot/restore method. | `bool` | `false` | no |
| <a name="input_persistent_volume_claims"></a> [persistent\_volume\_claims](#input\_persistent\_volume\_claims) | Configuration for Kubernetes PersistentVolumeClaims. | <pre>map(object({<br>    name               = string<br>    namespace          = string<br>    annotations        = optional(map(string), {})<br>    labels             = optional(map(string), {})<br>    access_mode        = optional(string, "ReadWriteOnce")<br>    storage_class_name = string<br>    pv_ref             = optional(string) # Optional to allow dynamic provisioning<br>    size_gb            = number<br>  }))</pre> | `{}` | no |
| <a name="input_persistent_volumes"></a> [persistent\_volumes](#input\_persistent\_volumes) | Configuration for Kubernetes PersistentVolumes. | <pre>map(object({<br>    name               = string<br>    annotations        = optional(map(string), {})<br>    labels             = optional(map(string), {})<br>    size_gb            = number<br>    access_mode        = optional(string, "ReadWriteOnce")<br>    storage_class_name = string<br>    reclaim_policy     = optional(string, "Retain")<br>    volume_mode        = optional(string, "Filesystem")<br>    use_module_disk    = optional(bool, false)  # Set to true to use the disk created by this module<br>    disk_ref           = optional(string)       # Only needed for referencing external disks<br>    disk_name          = optional(string)       # Only needed for referencing external disks by name<br>    fs_type            = optional(string, "ext4")<br>    read_only          = optional(bool, false)<br>  }))</pre> | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project ID where resources will be created. | `string` | n/a | yes |
| <a name="input_replication_target"></a> [replication\_target](#input\_replication\_target) | Configuration for the replication target location in another region. | <pre>object({<br>    location = string  # Must be a zone in a different region<br>  })</pre> | `null` | no |
| <a name="input_storage_classes"></a> [storage\_classes](#input\_storage\_classes) | Configuration for Kubernetes StorageClasses. | <pre>map(object({<br>    name                   = string<br>    is_default             = optional(bool, false)<br>    annotations            = optional(map(string), {})<br>    labels                 = optional(map(string), {})<br>    reclaim_policy         = optional(string, "Delete")<br>    volume_binding_mode    = optional(string, "WaitForFirstConsumer")<br>    allow_volume_expansion = optional(bool, true)<br>    disk_type              = optional(string, "pd-standard")<br>    parameters             = optional(map(string), {})<br>    use_module_disk        = optional(bool, false) # Set to true to use the disk created by this module<br>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_async_replication"></a> [async\_replication](#output\_async\_replication) | The disk async replication resource (if created) |
| <a name="output_persistent_volume_claim_names"></a> [persistent\_volume\_claim\_names](#output\_persistent\_volume\_claim\_names) | The names of the created Kubernetes PersistentVolumeClaim resources |
| <a name="output_persistent_volume_claims"></a> [persistent\_volume\_claims](#output\_persistent\_volume\_claims) | The created Kubernetes PersistentVolumeClaim resources |
| <a name="output_persistent_volume_names"></a> [persistent\_volume\_names](#output\_persistent\_volume\_names) | The names of the created Kubernetes PersistentVolume resources |
| <a name="output_persistent_volumes"></a> [persistent\_volumes](#output\_persistent\_volumes) | The created Kubernetes PersistentVolume resources |
| <a name="output_regional_disk"></a> [regional\_disk](#output\_regional\_disk) | The regional disk resource (if created) |
| <a name="output_regional_disk_id"></a> [regional\_disk\_id](#output\_regional\_disk\_id) | The ID of the regional disk (if created) |
| <a name="output_regional_disk_name"></a> [regional\_disk\_name](#output\_regional\_disk\_name) | The name of the regional disk (if created) |
| <a name="output_regional_disk_snapshot_id"></a> [regional\_disk\_snapshot\_id](#output\_regional\_disk\_snapshot\_id) | The ID of the regional disk snapshot that can be used for disaster recovery |
| <a name="output_regional_disk_snapshot_self_link"></a> [regional\_disk\_snapshot\_self\_link](#output\_regional\_disk\_snapshot\_self\_link) | The self\_link of the regional disk snapshot that can be used for disaster recovery |
| <a name="output_replication_target_disk"></a> [replication\_target\_disk](#output\_replication\_target\_disk) | The replication target disk resource (if created) |
| <a name="output_replication_target_disk_id"></a> [replication\_target\_disk\_id](#output\_replication\_target\_disk\_id) | The ID of the replication target disk (if created) |
| <a name="output_resources_summary"></a> [resources\_summary](#output\_resources\_summary) | Summary of all resources created by this module |
| <a name="output_storage_class_names"></a> [storage\_class\_names](#output\_storage\_class\_names) | The names of the created Kubernetes StorageClass resources |
| <a name="output_storage_classes"></a> [storage\_classes](#output\_storage\_classes) | The created Kubernetes StorageClass resources |
| <a name="output_zonal_disk"></a> [zonal\_disk](#output\_zonal\_disk) | The zonal disk resource (if created) |
| <a name="output_zonal_disk_id"></a> [zonal\_disk\_id](#output\_zonal\_disk\_id) | The ID of the zonal disk (if created) |
| <a name="output_zonal_disk_name"></a> [zonal\_disk\_name](#output\_zonal\_disk\_name) | The name of the zonal disk (if created) |
