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

- **Bastion Host (tf-bastion)**
  - Punto de entrada seguro a la red interna.
  - Utiliza Ubuntu 22.04.
  - Grupo de seguridad: `tf_sg_bastion`.
    - Permite SSH (puerto 22) e ICMP desde Internet.
  - Tiene una IP flotante para acceso externo.

- **Servidor de Base de Datos MySQL (tf-db)**
  - Aloja la base de datos para Metabase.
  - Utiliza una imagen personalizada de MySQL en Ubuntu 18.04.
  - Grupo de seguridad: `tf_sg_db`.
    - Permite tráfico MySQL desde Metabase.
    - Permite SSH desde el Bastion Host.

- **Servidor Metabase (tf_metabase)**
  - Ejecuta la aplicación Metabase.
  - Utiliza Ubuntu 22.04 con Docker preinstalado.
  - Grupo de seguridad: `tf_sg_metabase`.
    - Permite tráfico al puerto 3000 desde el balanceador de carga.
    - Permite SSH desde el Bastion Host.

- **Balanceador de Carga (tf-lb)**
  - Actúa como punto de entrada para Metabase.
  - Utiliza Nginx en Ubuntu 18.04.
  - Grupo de seguridad: `tf_sg_lb`.
    - Permite tráfico HTTP (puerto 80) desde Internet.
    - Permite SSH desde el Bastion Host.
  - Tiene una IP flotante para acceso público.

- **Red y Enrutamiento**
  - Red privada (tf-net) con subnet `172.19.0.0/24`.
  - Router (tf-router) conectando la red privada a la red externa.


## Notas importantes

- Asegúrate de tener configuradas correctamente tus credenciales de OpenStack.
- El archivo `variables.tf` contiene variables que puedes personalizar según tus necesidades.
- La clave SSH utilizada está definida en la variable `key_name` en el archivo `variables.tf`. Asegúrate de reemplazarla con el nombre de tu clave SSH en OpenStack.




    