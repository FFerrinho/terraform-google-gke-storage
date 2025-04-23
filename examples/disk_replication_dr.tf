# Example: Disk with cross-region replication for disaster recovery
# This demonstrates setting up asynchronous replication for a zonal disk

module "replicated_storage" {
  source = "../"
  
  project_id = "my-gcp-project"
  
  # Create a zonal disk
  disk = {
    name       = "critical-data"
    size_gb    = 500
    disk_type  = "pd-ssd"
    location   = "us-central1-a"
  }
  
  # Configure replication target in another region
  replication_target = {
    location = "us-west1-a"  # Different region
  }
  
  # Create a storage class
  storage_classes = {
    "critical-storage" = {
      name      = "critical-storage"
      disk_type = "pd-ssd"
    }
  }
  
  # Create a PV referencing the zonal disk
  persistent_volumes = {
    "critical-data-pv" = {
      name               = "critical-data-pv"
      size_gb            = 500
      storage_class_name = "critical-storage"
      use_module_disk    = true
    }
  }
  
  # Create a PVC referencing the PV
  persistent_volume_claims = {
    "critical-data-pvc" = {
      name               = "critical-data-pvc"
      namespace          = "mission-critical"
      storage_class_name = "critical-storage"
      pv_ref             = "critical-data-pv"
      size_gb            = 500
    }
  }
}
