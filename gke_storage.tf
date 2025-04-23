resource "kubernetes_storage_class_v1" "main" {
  for_each = var.storage_classes

  metadata {
    name = each.value.name
    annotations = merge(
      {
        "storageclass.kubernetes.io/is-default-class" = each.value.is_default ? "true" : "false"
      },
      each.value.annotations
    )
    labels = each.value.labels
  }

  storage_provisioner    = "pd.csi.storage.gke.io"
  reclaim_policy         = each.value.reclaim_policy
  volume_binding_mode    = each.value.use_module_disk ? "Immediate" : each.value.volume_binding_mode
  allow_volume_expansion = each.value.allow_volume_expansion

  parameters = merge(
    {
      type = each.value.disk_type
    },
    each.value.parameters
  )
}

locals {
  # Create variables for easier disk reference
  zonal_disk_name    = length(google_compute_disk.main) > 0 ? one(google_compute_disk.main[*].name) : null
  regional_disk_name = length(google_compute_region_disk.main) > 0 ? one(google_compute_region_disk.main[*].name) : null
  
  # Flag to check if any disk was created
  disk_created = local.zonal_disk_name != null || local.regional_disk_name != null
  
  # Flag to check if it's a zonal or regional disk
  is_zonal_disk = local.zonal_disk_name != null
  
  # Process persistent volumes to determine disk references
  processed_pvs = {
    for k, v in var.persistent_volumes : k => {
      # Auto-link to the created disk if requested
      use_module_disk = lookup(v, "use_module_disk", false) && local.disk_created
      
      # Determine if it's a zonal or regional disk
      is_zonal_disk = local.is_zonal_disk
    }
  }
}

resource "kubernetes_persistent_volume_v1" "main" {
  for_each = var.persistent_volumes

  metadata {
    name        = each.value.name
    annotations = each.value.annotations
    labels      = each.value.labels
  }

  spec {
    capacity = {
      storage = "${each.value.size_gb}Gi"
    }

    access_modes                     = [each.value.access_mode]
    storage_class_name               = each.value.storage_class_name
    persistent_volume_reclaim_policy = each.value.reclaim_policy
    volume_mode                      = each.value.volume_mode

    persistent_volume_source {
      # Conditional for zonal disk
      dynamic "gce_persistent_disk" {
        for_each = local.processed_pvs[each.key].use_module_disk && local.processed_pvs[each.key].is_zonal_disk ? [1] : []
        content {
          pd_name   = local.zonal_disk_name
          fs_type   = each.value.fs_type
          read_only = each.value.read_only
        }
      }

      # Conditional for regional disk or dynamic provisioning
      dynamic "csi" {
        for_each = local.processed_pvs[each.key].use_module_disk && !local.processed_pvs[each.key].is_zonal_disk ? [1] : (!local.processed_pvs[each.key].use_module_disk ? [1] : [])
        content {
          driver = "pd.csi.storage.gke.io"
          
          volume_handle = local.processed_pvs[each.key].use_module_disk && !local.processed_pvs[each.key].is_zonal_disk ? local.regional_disk_name : "dynamic-${each.value.name}"
          
          fs_type   = each.value.fs_type
          read_only = lookup(each.value, "read_only", false)
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "main" {
  for_each = var.persistent_volume_claims

  metadata {
    name        = each.value.name
    namespace   = each.value.namespace
    annotations = each.value.annotations
    labels      = each.value.labels
  }

  spec {
    access_modes       = [each.value.access_mode]
    storage_class_name = each.value.storage_class_name
    volume_name        = lookup(each.value, "pv_ref", null) != null ? kubernetes_persistent_volume_v1.main[each.value.pv_ref].metadata[0].name : null

    resources {
      requests = {
        storage = "${each.value.size_gb}Gi"
      }
    }
  }
}
