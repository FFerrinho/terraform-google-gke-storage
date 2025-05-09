# Disco persistente zonal.
resource "google_compute_disk" "principal" {
  for_each = var.disco.nome != null && can(regex(".*-[a-z]$", var.disco.localizacao)) ? { (var.disco.nome) = var.disco } : {}

  name                      = "${each.value.nome}-${replace(each.value.localizacao, "/", "-")}"
  description               = each.value.descricao
  labels                    = each.value.etiquetas
  size                      = each.value.tamanho_gb
  physical_block_size_bytes = each.value.tamanho_bloco_fisico_bytes
  type                      = each.value.tipo_disco
  access_mode               = each.value.modo_acesso
  project                   = var.id_projeto
  zone                      = each.value.localizacao
}

# Disco persistente regional com redundância a nível de zona.
resource "google_compute_region_disk" "principal" {
  for_each = var.disco.nome != null && !can(regex(".*-[a-z]$", var.disco.localizacao)) ? { (var.disco.nome) = var.disco } : {}

  name                      = "${each.value.nome}-${each.value.localizacao}"
  description               = each.value.descricao
  labels                    = each.value.etiquetas
  size                      = each.value.tamanho_gb
  physical_block_size_bytes = each.value.tamanho_bloco_fisico_bytes
  type                      = each.value.tipo_disco
  project                   = var.id_projeto
  region                    = each.value.localizacao
  replica_zones             = each.value.zonas_replica

  lifecycle {
    precondition {
      condition     = each.value.zonas_replica != null && length(each.value.zonas_replica) > 0
      error_message = "O disco regional deve ter zonas de réplica especificadas. Por favor, indique pelo menos duas zonas na região."
    }
  }
}

# Disco secundário para replicação entre regiões.
resource "google_compute_disk" "alvo_replicacao" {
  for_each = var.alvo_replicacao != null && length(google_compute_disk.principal) > 0 ? { (var.disco.nome) = var.disco } : {}

  name                      = "${var.disco.nome}-replica-${replace(var.alvo_replicacao.localizacao, "/", "-")}"
  description               = var.disco.descricao
  labels                    = var.disco.etiquetas
  size                      = var.disco.tamanho_gb
  physical_block_size_bytes = var.disco.tamanho_bloco_fisico_bytes
  type                      = var.disco.tipo_disco
  access_mode               = var.disco.modo_acesso
  project                   = var.id_projeto
  zone                      = var.alvo_replicacao.localizacao

  lifecycle {
    precondition {
      condition     = substr(var.alvo_replicacao.localizacao, 0, length(var.alvo_replicacao.localizacao) - 2) != substr(var.disco.localizacao, 0, length(var.disco.localizacao) - 2)
      error_message = "O alvo de replicação deve estar numa região diferente do disco de origem."
    }
  }
}

# Replicação assíncrona entre o disco primário e secundário.
resource "google_compute_disk_async_replication" "replicacao" {
  for_each = var.alvo_replicacao != null && length(google_compute_disk.principal) > 0 ? { ("${var.disco.nome}-para-${var.alvo_replicacao.localizacao}") = true } : {}

  primary_disk = one(google_compute_disk.principal[*].id)
  secondary_disk {
    disk = one(google_compute_disk.alvo_replicacao[*].id)
  }
}

# Snapshot para recuperação de desastres do disco regional.
resource "google_compute_snapshot" "snapshot_disco_regional" {
  for_each = var.alvo_replicacao != null && length(google_compute_region_disk.principal) > 0 && var.ativar_replicacao_disco_regional ? { ("${var.disco.nome}-snapshot") = true } : {}

  name              = "${var.disco.nome}-${var.disco.localizacao}-snapshot"
  source_disk       = one(google_compute_region_disk.principal[*].self_link)
  zone              = one(var.disco.zonas_replica)
  description       = "Snapshot do disco regional ${var.disco.nome}."
  storage_locations = [substr(var.alvo_replicacao.localizacao, 0, length(var.alvo_replicacao.localizacao) - 2)]
}
