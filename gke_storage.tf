# Criar classes de armazenamento Kubernetes.
resource "kubernetes_storage_class_v1" "principal" {
  for_each = var.storage_class

  metadata {
    name = each.value.nome
    annotations = merge(
      {
        "storageclass.kubernetes.io/is-default-class" = each.value.e_padrao ? "true" : "false"
      },
      each.value.anotacoes
    )
    labels = each.value.etiquetas
  }

  storage_provisioner    = "pd.csi.storage.gke.io"
  reclaim_policy         = each.value.politica_recuperacao
  volume_binding_mode    = each.value.usar_disco_modulo  == true ? "Immediate" : each.value.modo_vinculacao_volume
  allow_volume_expansion = each.value.permitir_expansao_volume

  parameters = merge(
    {
      type = each.value.tipo_disco
    },
    each.value.parametros
  )
}

locals {
  # Criar variáveis para referência de disco mais fácil.
  nome_disco_zonal    = length(google_compute_disk.principal) > 0 ? one(values(google_compute_disk.principal)[*].name) : null
  nome_disco_regional = length(google_compute_region_disk.principal) > 0 ? one(values(google_compute_region_disk.principal)[*].name) : null
}

# Criar volumes persistentes Kubernetes.
resource "kubernetes_persistent_volume_v1" "principal" {
  for_each = var.persistent_volume

  metadata {
    name        = each.value.nome
    annotations = each.value.anotacoes
    labels      = each.value.etiquetas
  }

  spec {
    capacity = {
      storage = "${each.value.tamanho_gb}Gi"
    }

    access_modes = [each.value.modo_acesso]

    # Avalia se a Storageclass foi criada no módulo ou se espera receber o valor pela varíavel.
    storage_class_name               = lookup(each.value, "nome_classe_armazenamento", null) != null ? each.value.nome_classe_armazenamento : length(var.storage_class) > 0 ? kubernetes_storage_class_v1.principal[keys(var.storage_class)[0]].metadata[0].name : null
    persistent_volume_reclaim_policy = each.value.politica_recuperacao
    volume_mode                      = each.value.modo_volume

    persistent_volume_source {
      # Avalia se foi criado e usa um disco zonal.
      dynamic "gce_persistent_disk" {
        for_each = lookup(each.value, "usar_disco_modulo", false) && local.nome_disco_zonal != null ? [1] : []
        content {
          pd_name   = local.nome_disco_zonal
          fs_type   = each.value.tipo_fs
          read_only = lookup(each.value, "read_only", false)
        }
      }

      # Avalia se foi criado e usa um disco regional ou aprovisionamento dinâmico.
      dynamic "csi" {
        for_each = lookup(each.value, "usar_disco_modulo", false) && local.nome_disco_regional != null ? [1] : (!lookup(each.value, "usar_disco_modulo", false) ? [1] : [])
        content {
          driver        = "pd.csi.storage.gke.io"
          volume_handle = lookup(each.value, "usar_disco_modulo", false) && local.nome_disco_regional != null ? local.nome_disco_regional : "dynamic-${each.value.name}"
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "principal" {
  for_each = var.persistent_volume_claim

  metadata {
    name        = each.value.nome
    namespace   = each.value.namespace
    annotations = each.value.anotacoes
    labels      = each.value.etiquetas
  }

  spec {
    access_modes = [each.value.modo_acesso]

    # Avalia se a Storageclass foi criada no módulo ou se espera receber o valor pela varíavel.
    storage_class_name = lookup(each.value, "nome_classe_armazenamento", null) != null ? each.value.nome_classe_armazenamento : length(var.storage_class) > 0 ? kubernetes_storage_class_v1.principal[keys(var.storage_class)[0]].metadata[0].name : null

    # Avalia se PersistentVolume foi criada no módulo ou se espera receber o valor pela varíavel.
    volume_name = lookup(each.value, "nome_volume", null) != null ? each.value.nome_volume : length(var.persistent_volume) > 0 ? kubernetes_persistent_volume_v1.principal[keys(var.persistent_volume)[0]].metadata[0].name : null

    resources {
      requests = {
        storage = "${each.value.tamanho_gb}Gi"
      }
    }
  }
}
