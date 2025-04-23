# Example: Dynamic provisioning with StorageClass and PVC
# This demonstrates dynamic provisioning without pre-creating a disk or PV

module "dynamic_storage" {
  source = "../"
  
  project_id = "my-gcp-project"
  
  # Create a storage class for dynamic provisioning
  storage_classes = {
    "dynamic-storage" = {
      name                   = "dynamic-storage"
      disk_type              = "pd-balanced"
      reclaim_policy         = "Delete"
      volume_binding_mode    = "WaitForFirstConsumer"
      allow_volume_expansion = true
    }
  }
  
  # Create a PVC that will trigger dynamic provisioning
  persistent_volume_claims = {
    "dynamic-data-pvc" = {
      name               = "dynamic-data-pvc"
      namespace          = "app"
      storage_class_name = "dynamic-storage"
      # No pv_ref - will be dynamically provisioned
      size_gb            = 50
    }
  }
}
