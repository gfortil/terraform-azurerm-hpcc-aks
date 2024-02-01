resource "kubernetes_namespace" "hpcc" {
  count = var.hpcc_namespace.create_namespace && !fileexists("${path.module}/modules/logging/data/hpcc_namespace.txt") ? 1 : 0

  metadata {
    labels = var.hpcc_namespace.labels
    name   = "${substr(trimspace(var.owner.name), 0, 5)}${random_integer.random.result}"
    # generate_name = "${trimspace(var.owner.name)}"
  }
}

module "hpcc" {
  # source = "github.com/gfortil/opinionated-terraform-azurerm-hpcc?ref=HPCC-27615"
  source = "../../../opinionated/opinionated-terraform-azurerm-hpcc"

  log_access_role_assignment = {
    enabled   = false
    scope     = null
    object_id = null
  }

  environment = var.metadata.environment
  productname = var.metadata.product_name

  internal_domain = var.internal_domain
  cluster_name    = local.get_aks_config.cluster_name

  node_tuning_containers = var.node_tuning_containers

  helm_chart_version = var.helm_chart_version

  hpcc_container = {
    image_name = var.hpcc_container.image_name
    image_root = var.hpcc_container.image_root
    version    = var.hpcc_container.version
  }

  hpcc_container_registry_auth = var.hpcc_container_registry_auth != null ? {
    password = var.hpcc_container_registry_auth.password
    username = var.hpcc_container_registry_auth.username
  } : null

  install_blob_csi_driver = false //Disable CSI driver

  resource_group_name = local.get_aks_config.resource_group_name
  location            = var.metadata.location
  tags                = module.metadata.tags

  # namespace = local.hpcc_namespace
  namespace = {
    create_namespace = false
    name             = local.hpcc_namespace
    labels           = var.hpcc_namespace.labels
  }

  admin_services_storage_account_settings = {
    replication_type     = var.admin_services_storage_account_settings.replication_type
    authorized_ip_ranges = merge(var.admin_services_storage_account_settings.authorized_ip_ranges, { host_ip = data.http.host_ip.response_body })
    delete_protection    = var.admin_services_storage_account_settings.delete_protection
    subnet_ids           = merge({ aks = local.subnet_ids.aks })
  }

  data_storage_config = {
    internal = local.external_storage_accounts == null ? {
      blob_nfs = {
        data_plane_count = var.data_storage_config.internal.blob_nfs.data_plane_count
        storage_account_settings = {
          replication_type     = var.data_storage_config.internal.blob_nfs.storage_account_settings.replication_type
          authorized_ip_ranges = merge(var.admin_services_storage_account_settings.authorized_ip_ranges, { host_ip = data.http.host_ip.response_body })
          delete_protection    = var.data_storage_config.internal.blob_nfs.storage_account_settings.delete_protection
          subnet_ids           = merge({ aks = local.subnet_ids.aks })
        }
      }
      hpc_cache      = null
      netapp_volumes = null
    } : null

    # external = local.internal_data_storage_enabled ? null : {
    #   blob_nfs = local.get_storage_config != null ? local.get_storage_config.data_storage_planes : var.data_storage_config.external.blob_nfs
    #   hpcc     = null
    # }
    external = null
  }

  enable_node_tuning = var.enable_node_tuning

  external_storage_accounts = local.external_storage_accounts

  spill_volumes                = var.spill_volumes
  roxie_config                 = var.roxie_config
  thor_config                  = var.thor_config
  vault_config                 = var.vault_config
  eclccserver_settings         = var.eclccserver_settings
  spray_service_settings       = var.spray_service_settings
  admin_services_node_selector = { all = { workload = var.spray_service_settings.nodeSelector } }

  esp_remoteclients = {

    "sample-remoteclient" = {

      name = "sample-remoteclient"

      labels = {

        "test" = "client"

      }

    }

  }

  helm_chart_timeout = var.helm_chart_timeout
  # helm_chart_files_overrides = concat(var.helm_chart_files_overrides, fileexists("${path.module}/modules/logging/data/logaccess_body.yaml") ? ["${path.module}/modules/logging/data/logaccess_body.yaml"] : [])
  ldap_config = var.ldap_config

  expose_services = var.expose_services
}
