# Example: Creating a zonal disk with associated PV and PVC
# This demonstrates creating a zonal disk and connecting it to a PV and PVC

module "zonal_disk_storage" {
  source = "../"
  
  project_id = "my-gcp-project"
  
  # Create a zonal disk
  disk = {
    name       = "app-data"
    size_gb    = 100
    disk_type  = "pd-ssd"
    location   = "us-central1-a"  # Zone format
  }
  
  # Create a storage class
  storage_classes = {
    "fast-storage" = {
      name      = "fast-storage"
      disk_type = "pd-ssd"
    }
  }
  
  # Create a PV referencing the disk
  persistent_volumes = {
    "app-data-pv" = {
      name               = "app-data-pv"
      size_gb            = 100
      storage_class_name = "fast-storage"
      use_module_disk    = true  # Auto-link to the disk created above
    }
  }
  
  # Create a PVC referencing the PV
  persistent_volume_claims = {
    "app-data-pvc" = {
      name               = "app-data-pvc"
      namespace          = "default"
      storage_class_name = "fast-storage"
      pv_ref             = "app-data-pv"  # Reference to the PV key above
      size_gb            = 100
    }
  }
}
