### Caso 01

### Caso 02
# Proyecto de Infraestructura con Terraform

Este proyecto utiliza Terraform para desplegar una infraestructura en OpenStack que incluye una base de datos MySQL, un servidor Metabase y un balanceador de carga.

## Requisitos previos

- Terraform instalado (versión 1.5 o superior)
- Acceso a una plataforma OpenStack
- Clave SSH configurada en OpenStack

## Configuración inicial

1. Clona este repositorio.
2. Crea un archivo `.env` en la raíz del proyecto con las siguientes variables:

```bash

TF_VAR_google_db_password=password
TF_VAR_metabase_password=password
TF_VAR_admin_email=mail@example.com
```

3. Ejecuta el script para cargar las variables de entorno:

```bash
source read-variables.sh
```

## Despliegue

1. Inicializa Terraform:
```bash
terraform init
```
2. Revisa el plan de Terraform:
```bash
terraform plan
```
3. Aplica la configuración:
```bash
terraform apply
```
## Componentes desplegados

- Bastion host
- Servidor de base de datos MySQL
- Servidor Metabase
- Balanceador de carga

## Notas importantes

- Asegúrate de tener configuradas correctamente tus credenciales de OpenStack.
- El archivo `variables.tf` contiene variables que puedes personalizar según tus necesidades.
- La clave SSH utilizada está definida en la variable `key_name` en el archivo `variables.tf`. Asegúrate de reemplazarla con el nombre de tu clave SSH en OpenStack.




    