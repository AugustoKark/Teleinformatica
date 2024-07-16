### Caso 01
# Red WAN Nacional con Mininet

Este proyecto implementa una simulación de una red WAN nacional para una organización con 6 sucursales utilizando Mininet. La red está diseñada con una topología estrella, donde cada sucursal se conecta a una casa matriz central.

## Estructura de la Red

- **Red WAN**: 192.168.100.0/24, dividida en subredes /29 para los enlaces
- **Redes LAN**: Cada sucursal utiliza una red 10.0.n.0/24

### Direccionamiento

- **Casa Matriz**: Router central conectado a todas las sucursales
- **Sucursales**: 6 sucursales, cada una con su propio router y red interna

## Implementación en Mininet

El script de Python incluido en este repositorio crea la siguiente topología:

- 1 router central (Casa Matriz)
- 6 routers de sucursal
- 6 hosts (uno por sucursal)
- Switches para conectar los routers y hosts

### Características del Script

- Crea la topología completa con 7 routers y 6 hosts
- Configura las interfaces de red con las direcciones IP correspondientes
- Establece las rutas necesarias para la comunicación entre sucursales
- Utiliza switches OVS en modo standalone

## Requisitos

- Mininet
- Python 2.7 o superior



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



### Caso 03
# Despliegue de Metabase en Kubernetes

Este repositorio contiene manifiestos de Kubernetes para desplegar Metabase con una base de datos MySQL, enfocado en el análisis de datos de movilidad para la Provincia de Mendoza, Departamento Capital.

## Componentes

1. **Base de Datos MySQL**
   - Desplegada como un StatefulSet
   - Incluye ConfigMaps para configuración e inicialización
   - Utiliza un PersistentVolumeClaim para persistencia de datos
   - Job para carga de datos y configuración de la base de datos

2. **Metabase**
   - Desplegado como un Deployment
   - Configurado para conectarse a la base de datos MySQL
   - Incluye chequeos de salud y sondas de disponibilidad
   - Job para configuración inicial y creación de dashboard

3. **Ingress**
   - Configurado para acceso externo a Metabase

4. **Secrets**
   - Para almacenar información sensible como contraseñas y credenciales



## Requisitos Previos

- Clúster de Kubernetes
- kubectl configurado para interactuar con tu clúster
- Controlador de Ingress (por ejemplo, NGINX Ingress) instalado en el clúster





    