resource "azurerm_service_plan" "this" {
  name                = var.appservice_plan_name
  location            = var.location
  resource_group_name = var.rg_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = var.webapp_name
  location            = var.location
  resource_group_name = var.rg_name
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true

  site_config {
    application_stack {
      docker_image_name        = "${var.image_name}:${var.image_tag}"
      docker_registry_url      = "https://${var.acr_login_server}"
      docker_registry_username = var.acr_admin_username
      docker_registry_password = var.acr_admin_password
    }
    
    minimum_tls_version = "1.2"
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    WEBSITES_PORT               = "80"
    DOCKER_ENABLE_CI            = "true"
    
    APP_DEBUG                   = var.app_debug
    APP_ENV                     = var.app_env
    APP_KEY                     = "base64:DJYTvaRkEZ/YcQsX3TMpB0iCjgme2rhlIOus9A1hnj4="
    
    DB_CONNECTION               = "mysql"
    DB_HOST                     = var.mysql_fqdn
    DB_PORT                     = "3306"
    DB_DATABASE                 = var.database_name
    DB_USERNAME                 = var.mysql_admin_username
    DB_PASSWORD                 = var.mysql_admin_password
  }

  tags = var.tags
}

# Note: Docker image build and push is now handled separately via:
# - scripts/build-push-image.sh for manual deployments
# - GitHub Actions workflow docker-build.yml for CI/CD
# The image must be present in ACR before deploying the App Service
