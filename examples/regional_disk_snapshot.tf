# Example: Regional disk with snapshot-based disaster recovery
# This demonstrates creating a snapshot of a regional disk for DR purposes

module "ha_storage_with_snapshot" {
  source = "../"
  
  project_id = "my-gcp-project"
  
  # Create a regional disk
  disk = {
    name          = "important-data"
    size_gb       = 300
    disk_type     = "pd-ssd"
    location      = "us-central1"
    replica_zones = ["us-central1-a", "us-central1-b"]
  }
  
  # Configure snapshot target in another region
  replication_target = {
    location = "us-east1-b"
  }
  
  # Enable snapshot-based replication for the regional disk
  enable_regional_disk_replication = true
  
  # Create associated Kubernetes resources
  storage_classes = {
    "important-storage" = {
      name      = "important-storage"
      disk_type = "pd-ssd"
    }
  }
  
  persistent_volumes = {
    "important-data-pv" = {
      name               = "important-data-pv"
      size_gb            = 300
      storage_class_name = "important-storage"
      use_module_disk    = true
    }
  }
  
  persistent_volume_claims = {
    "important-data-pvc" = {
      name               = "important-data-pvc"
      namespace          = "data-services"
      storage_class_name = "important-storage"
      pv_ref             = "important-data-pv"
      size_gb            = 300
    }
  }
}
