variable "id_projeto" {
  description = "ID do projeto onde os recursos serão criados."
  type        = string
}

variable "disco" {
  description = "Configuração para o disco persistente a ser criado no módulo."
  type = object({
    nome                       = optional(string)
    descricao                  = optional(string)
    etiquetas                  = optional(map(string), {})
    tamanho_gb                 = optional(number, 10)
    tamanho_bloco_fisico_bytes = optional(number, 4096)
    tipo_disco                 = optional(string, "pd-standard")
    modo_acesso                = optional(string, "READ_WRITE_SINGLE")
    localizacao                = optional(string)      # Zona (ex: "europe-west1-b") ou região (ex: "europe-west1").
    zonas_replica              = optional(set(string)) # Obrigatório se a localização for uma região.
  })
  default = null

  validation {
    condition = var.disco == null || contains([
      "pd-standard", "pd-balanced", "pd-ssd", "pd-extreme", "hyperdisk-balanced",
      "hyperdisk-throughput", "hyperdisk-extreme"
    ], var.disco.tipo_disco)
    error_message = "O tipo_disco deve ser um dos seguintes: pd-standard, pd-balanced, pd-ssd, pd-extreme, hyperdisk-balanced, hyperdisk-throughput, hyperdisk-extreme."
  }
}

variable "alvo_replicacao" {
  description = "Configuração para a localização do alvo de replicação em outra região."
  type = object({
    localizacao = string # Deve ser uma zona em uma região diferente.
  })
  default = null
}

variable "ativar_replicacao_disco_regional" {
  description = "Indica se deve ser ativada a replicação de discos regionais usando o método de snapshot/restauração."
  type        = bool
  default     = false
}

variable "storage_class" {
  description = "Configuração para as classes de armazenamento do Kubernetes."
  type = map(object({
    nome                     = string
    e_padrao                 = optional(bool, false)
    anotacoes                = optional(map(string), {})
    etiquetas                = optional(map(string), {})
    politica_recuperacao     = optional(string, "Delete")
    modo_vinculacao_volume   = optional(string, "WaitForFirstConsumer")
    permitir_expansao_volume = optional(bool, true)
    tipo_disco               = optional(string, "pd-standard")
    parametros               = optional(map(string), {})
    usar_disco_modulo        = optional(bool, false) # Definir como true para usar o disco criado por este módulo.
  }))
  default = {}

  validation {
    condition = length([
      for k, v in var.storage_class :
      v if !contains([
        "pd-standard", "pd-balanced", "pd-ssd", "pd-extreme", "hyperdisk-balanced",
        "hyperdisk-throughput", "hyperdisk-extreme"
      ], v.tipo_disco)
    ]) == 0
    error_message = "Todas as classes de armazenamento devem ter um tipo_disco válido: pd-standard, pd-balanced, pd-ssd, pd-extreme, hyperdisk-balanced, hyperdisk-throughput, hyperdisk-extreme."
  }
}

variable "persistent_volume" {
  description = "Configuração para os volumes persistentes do Kubernetes."
  type = map(object({
    nome                      = string
    anotacoes                 = optional(map(string), {})
    etiquetas                 = optional(map(string), {})
    tamanho_gb                = number
    modo_acesso               = optional(string, "ReadWriteOnce")
    nome_classe_armazenamento = optional(string)
    politica_recuperacao      = optional(string, "Retain")
    modo_volume               = optional(string, "Filesystem")
    usar_disco_modulo         = optional(bool, false) # Definir como true para usar o disco criado por este módulo.
    ref_disco                 = optional(string)      # Apenas necessário para referenciar discos externos.
    nome_disco                = optional(string)      # Apenas necessário para referenciar discos externos por nome.
    tipo_fs                   = optional(string, "ext4")
    somente_leitura           = optional(bool, false)
  }))
  default = {}
}

variable "persistent_volume_claim" {
  description = "Configuração para as reivindicações de volume persistente do Kubernetes."
  type = map(object({
    nome                      = string
    namespace                 = string
    anotacoes                 = optional(map(string), {})
    etiquetas                 = optional(map(string), {})
    modo_acesso               = optional(string, "ReadWriteOnce")
    nome_classe_armazenamento = optional(string)
    nome_volume                    = optional(string) # Referencia uma chave em persistent_volume.
    tamanho_gb                = number
  }))
  default = {}
}
