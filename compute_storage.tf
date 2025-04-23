# Zonal persistent disk 
resource "google_compute_disk" "main" {
  for_each = var.disk != null && can(regex("^[a-z]+-[a-z]+-[a-z]$", var.disk.location)) ? { (var.disk.name) = var.disk } : {}

  name                      = "${each.value.name}-${replace(each.value.location, "/", "-")}"
  description               = each.value.description
  labels                    = each.value.labels
  size                      = each.value.size_gb
  physical_block_size_bytes = each.value.physical_block_size_bytes
  type                      = each.value.disk_type
  access_mode               = each.value.access_mode
  project                   = var.project_id
  zone                      = each.value.location
}

# Regional persistent disk with zone-level redundancy
resource "google_compute_region_disk" "main" {
  for_each = var.disk != null && can(regex("^[a-z]+-[a-z]+$", var.disk.location)) ? { (var.disk.name) = var.disk } : {}

  name                      = "${each.value.name}-${each.value.location}"
  description               = each.value.description
  labels                    = each.value.labels
  size                      = each.value.size_gb
  physical_block_size_bytes = each.value.physical_block_size_bytes
  type                      = each.value.disk_type
  project                   = var.project_id
  region                    = each.value.location
  replica_zones             = each.value.replica_zones

  lifecycle {
    precondition {
      condition     = each.value.replica_zones != null && length(each.value.replica_zones) > 0
      error_message = "Regional disk must have replica_zones specified. Please provide at least two zones in the region."
    }
  }
}

# Secondary disk for cross-region replication
resource "google_compute_disk" "replication_target" {
  for_each = var.replication_target != null && length(google_compute_disk.main) > 0 ? { (var.disk.name) = var.disk } : {}

  name                      = "${var.disk.name}-replica-${replace(var.replication_target.location, "/", "-")}"
  description               = var.disk.description
  labels                    = var.disk.labels
  size                      = var.disk.size_gb
  physical_block_size_bytes = var.disk.physical_block_size_bytes
  type                      = var.disk.disk_type
  access_mode               = var.disk.access_mode
  project                   = var.project_id
  zone                      = var.replication_target.location

  lifecycle {
    precondition {
      condition     = substr(var.replication_target.location, 0, length(var.replication_target.location) - 2) != substr(var.disk.location, 0, length(var.disk.location) - 2)
      error_message = "Replication target must be in a different region than the source disk."
    }
  }
}

# Async replication between the primary and secondary disk
resource "google_compute_disk_async_replication" "replication" {
  for_each = var.replication_target != null && length(google_compute_disk.main) > 0 ? { ("${var.disk.name}-to-${var.replication_target.location}") = true } : {}

  primary_disk = one(google_compute_disk.main[*].id)
  secondary_disk {
    disk = one(google_compute_disk.replication_target[*].id)
  }
}

# Snapshot for regional disk disaster recovery
resource "google_compute_snapshot" "regional_disk_snapshot" {
  for_each = var.replication_target != null && length(google_compute_region_disk.main) > 0 && var.enable_regional_disk_replication ? { ("${var.disk.name}-snapshot") = true } : {}

  name              = "${var.disk.name}-${var.disk.location}-snapshot"
  source_disk       = one(google_compute_region_disk.main[*].self_link)
  zone              = one(var.disk.replica_zones) # Use one() to get an element from the set
  description       = "Snapshot of ${var.disk.name} regional disk for disaster recovery"
  storage_locations = [substr(var.replication_target.location, 0, length(var.replication_target.location) - 2)]
}
