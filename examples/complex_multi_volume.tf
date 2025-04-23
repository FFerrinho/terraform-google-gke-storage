# Example: Complex setup with multiple storage classes and volumes
# This demonstrates using multiple module instances to create different storage configurations

# Standard storage for general use
module "standard_storage" {
  source = "../"
  
  project_id = "my-gcp-project"
  
  storage_classes = {
    "standard" = {
      name      = "standard"
      is_default = true
      disk_type = "pd-standard"
    }
  }
}

# Fast storage for databases
module "database_storage" {
  source = "../"
  
  project_id = "my-gcp-project"
  
  disk = {
    name          = "db-data"
    size_gb       = 1000
    disk_type     = "pd-ssd"
    location      = "us-central1"
    replica_zones = ["us-central1-a", "us-central1-c"]
  }
  
  storage_classes = {
    "database-storage" = {
      name      = "database-storage"
      disk_type = "pd-ssd"
    }
  }
  
  persistent_volumes = {
    "db-data-pv" = {
      name               = "db-data-pv"
      size_gb            = 1000
      storage_class_name = "database-storage"
      use_module_disk    = true
      access_mode        = "ReadWriteMany"
    }
  }
  
  persistent_volume_claims = {
    "db-data-pvc" = {
      name               = "db-data-pvc"
      namespace          = "database"
      storage_class_name = "database-storage"
      pv_ref             = "db-data-pv"
      size_gb            = 1000
      access_mode        = "ReadWriteMany"
    }
  }
}

# Critical storage with cross-region replication
module "critical_storage" {
  source = "../"
  
  project_id = "my-gcp-project"
  
  disk = {
    name       = "critical-app-data"
    size_gb    = 200
    disk_type  = "pd-ssd"
    location   = "us-central1-a"
  }
  
  replication_target = {
    location = "us-west1-a"
  }
  
  storage_classes = {
    "critical-storage" = {
      name      = "critical-storage"
      disk_type = "pd-ssd"
    }
  }
  
  persistent_volumes = {
    "critical-app-pv" = {
      name               = "critical-app-pv"
      size_gb            = 200
      storage_class_name = "critical-storage"
      use_module_disk    = true
    }
  }
  
  persistent_volume_claims = {
    "critical-app-pvc" = {
      name               = "critical-app-pvc"
      namespace          = "critical-app"
      storage_class_name = "critical-storage"
      pv_ref             = "critical-app-pv"
      size_gb            = 200
    }
  }
}
