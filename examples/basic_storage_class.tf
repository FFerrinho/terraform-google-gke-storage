# Example: Creating just a StorageClass
# This creates a basic storage class in GKE without any associated disks

module "storage_class_only" {
  source = "../"
  
  project_id = "my-gcp-project"
  
  storage_classes = {
    "ssd-storage" = {
      name        = "ssd-storage"
      is_default  = true
      disk_type   = "pd-ssd"
      parameters  = {
        "replication-type" = "none"
      }
    }
  }
}
