# Example: Creating a regional disk with associated PV and PVC
# This demonstrates creating a regional disk for high availability

module "regional_disk_storage" {
  source = "../"
  
  project_id = "my-gcp-project"
  
  # Create a regional disk (replicated across two zones)
  disk = {
    name          = "ha-database"
    size_gb       = 200
    disk_type     = "pd-ssd"
    location      = "us-central1"  # Region format
    replica_zones = ["us-central1-a", "us-central1-c"]  # Must specify two zones
  }
  
  # Create a storage class
  storage_classes = {
    "ha-storage" = {
      name      = "ha-storage"
      disk_type = "pd-ssd"
    }
  }
  
  # Create a PV referencing the regional disk
  persistent_volumes = {
    "ha-database-pv" = {
      name               = "ha-database-pv"
      size_gb            = 200
      storage_class_name = "ha-storage"
      use_module_disk    = true  # Auto-link to the disk created above
      access_mode        = "ReadWriteMany"  # Regional disks support multi-writer
    }
  }
  
  # Create a PVC referencing the PV
  persistent_volume_claims = {
    "ha-database-pvc" = {
      name               = "ha-database-pvc"
      namespace          = "database"
      storage_class_name = "ha-storage"
      access_mode        = "ReadWriteMany"
      pv_ref             = "ha-database-pv"
      size_gb            = 200
    }
  }
}
