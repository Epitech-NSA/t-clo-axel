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

  site_config {
    application_stack {
      docker_image_name   = "${var.acr_login_server}/${var.image_name}:${var.image_tag}"
      docker_registry_username = var.acr_admin_username
      docker_registry_password = var.acr_admin_password
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    WEBSITES_PORT               = "80"
    
    APP_DEBUG                   = "true"
    APP_ENV                     = "production"
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

resource "null_resource" "docker_build_push" {
  triggers = {
    dockerfile_hash = filemd5("${var.app_source_path}/Dockerfile")
    source_hash     = sha1(join("", [for f in fileset("${var.app_source_path}", "**") : filesha1("${var.app_source_path}/${f}")]))
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      cd "${var.app_source_path}"
      
      # Variables
      ACR_NAME="${regex("[^.]+", var.acr_login_server)}"
      IMAGE_FULL_NAME="${var.acr_login_server}/${var.image_name}:${var.image_tag}"
      
      az acr login --name "$ACR_NAME"
      docker build -t "$IMAGE_FULL_NAME" .
      docker push "$IMAGE_FULL_NAME"
      
      echo "Successfully pushed $IMAGE_FULL_NAME"
    EOT
  }

  provisioner "local-exec" {
    when    = create
    command = "echo 'ACR ID: ${var.acr_id}'"
  }
}

