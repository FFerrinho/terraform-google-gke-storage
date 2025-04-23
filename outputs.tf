# Disk outputs
output "zonal_disk" {
  description = "The zonal disk resource (if created)"
  value       = length(google_compute_disk.main) > 0 ? one(google_compute_disk.main) : null
}

output "zonal_disk_id" {
  description = "The ID of the zonal disk (if created)"
  value       = length(google_compute_disk.main) > 0 ? one(google_compute_disk.main[*].id) : null
}

output "zonal_disk_name" {
  description = "The name of the zonal disk (if created)"
  value       = length(google_compute_disk.main) > 0 ? one(google_compute_disk.main[*].name) : null
}

output "regional_disk" {
  description = "The regional disk resource (if created)"
  value       = length(google_compute_region_disk.main) > 0 ? one(google_compute_region_disk.main) : null
}

output "regional_disk_id" {
  description = "The ID of the regional disk (if created)"
  value       = length(google_compute_region_disk.main) > 0 ? one(google_compute_region_disk.main[*].id) : null
}

output "regional_disk_name" {
  description = "The name of the regional disk (if created)"
  value       = length(google_compute_region_disk.main) > 0 ? one(google_compute_region_disk.main[*].name) : null
}

# Replication outputs
output "replication_target_disk" {
  description = "The replication target disk resource (if created)"
  value       = length(google_compute_disk.replication_target) > 0 ? one(google_compute_disk.replication_target) : null
}

output "replication_target_disk_id" {
  description = "The ID of the replication target disk (if created)"
  value       = length(google_compute_disk.replication_target) > 0 ? one(google_compute_disk.replication_target[*].id) : null
}

output "async_replication" {
  description = "The disk async replication resource (if created)"
  value       = length(google_compute_disk_async_replication.replication) > 0 ? one(google_compute_disk_async_replication.replication) : null
}

output "regional_disk_snapshot_id" {
  description = "The ID of the regional disk snapshot that can be used for disaster recovery"
  value       = length(google_compute_snapshot.regional_disk_snapshot) > 0 ? one(google_compute_snapshot.regional_disk_snapshot[*].id) : null
}

output "regional_disk_snapshot_self_link" {
  description = "The self_link of the regional disk snapshot that can be used for disaster recovery"
  value       = length(google_compute_snapshot.regional_disk_snapshot) > 0 ? one(google_compute_snapshot.regional_disk_snapshot[*].self_link) : null
}

# Kubernetes resources outputs
output "storage_classes" {
  description = "The created Kubernetes StorageClass resources"
  value       = kubernetes_storage_class_v1.main
}

output "storage_class_names" {
  description = "The names of the created Kubernetes StorageClass resources"
  value       = { for k, v in kubernetes_storage_class_v1.main : k => v.metadata[0].name }
}

output "persistent_volumes" {
  description = "The created Kubernetes PersistentVolume resources"
  value       = kubernetes_persistent_volume_v1.main
}

output "persistent_volume_names" {
  description = "The names of the created Kubernetes PersistentVolume resources"
  value       = { for k, v in kubernetes_persistent_volume_v1.main : k => v.metadata[0].name }
}

output "persistent_volume_claims" {
  description = "The created Kubernetes PersistentVolumeClaim resources"
  value       = kubernetes_persistent_volume_claim_v1.main
}

output "persistent_volume_claim_names" {
  description = "The names of the created Kubernetes PersistentVolumeClaim resources"
  value       = { for k, v in kubernetes_persistent_volume_claim_v1.main : k => v.metadata[0].name }
}

# Combined summary output
output "resources_summary" {
  description = "Summary of all resources created by this module"
  value = {
    zonal_disk_created     = length(google_compute_disk.main) > 0
    regional_disk_created  = length(google_compute_region_disk.main) > 0
    replication_configured = length(google_compute_disk_async_replication.replication) > 0 || length(google_compute_snapshot.regional_disk_snapshot) > 0
    storage_classes        = length(kubernetes_storage_class_v1.main)
    persistent_volumes     = length(kubernetes_persistent_volume_v1.main)
    persistent_volume_claims = length(kubernetes_persistent_volume_claim_v1.main)
  }
}
