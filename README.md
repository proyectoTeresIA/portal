# TeresIA – Portal e Interfaz de Usuario

## Descripción General

**TeresIA** es un proyecto cuyo objetivo es crear un **portal digital unificado** para la consulta, edición y validación colaborativa de terminologías en español y lenguas cooficiales.

El sistema integra tecnologías de **gestión ontológica**, **almacenamiento híbrido de datos** y **servicios de inteligencia artificial (IA)** para ofrecer:

- Búsqueda y navegación en catálogos terminológicos de múltiples dominios.
- Extracción y enriquecimiento semántico de terminologías mediante IA.
- Validación y sanción colaborativa de terminologías por expertos.

El desarrollo se basa en **OntoPortal** (plataforma de código abierto para ontologías), extendido con microservicios, APIs RESTful y un frontend moderno en React.

---

## Arquitectura General del Sistema

El sistema se estructura en cinco capas principales:

1. **OntoPortal como núcleo funcional**

   - Metabuscador y catálogo de terminologías.
   - Gestión de usuarios y permisos.

2. **Almacenamiento híbrido de datos**

   - Combinación de bases RDF y almacenamientos en crudo para datos procesados y terminologías:
     - **Virtuoso** y **AllegroGraph** para datos semánticos.
     - **Neo4j** para grafos de relaciones.
     - **Elasticsearch** para indexación y búsqueda documental.

3. **Servicios de IA**

   - Extracción automática de terminologías.
   - Enriquecimiento semántico: relaciones, desambiguación, enlazado.

4. **Frontend React**

   - Interfaz moderna para visualización, edición y validación colaborativa.

5. **Microservicios y API Gateway**
   - Comunicación estandarizada vía APIs RESTful.
   - Trazabilidad y auditoría integradas.

---

## Planificación por Hitos

El desarrollo se estructura en **6 hitos** (1 por mes), con entregas acumulativas:

| Mes | Hito                                          | Entregable                                                                  | % Avance |
| --- | --------------------------------------------- | --------------------------------------------------------------------------- | -------- |
| 1   | **E1 – Infraestructura**                      | Despliegue de OntoPortal, arquitectura técnica, CI/CD                       | 10%      |
| 2   | **E2 – Catálogo de Terminologías**            | OntoPortal adaptado, metabuscador funcional, ingesta RDF/CSV                | 20%      |
| 3   | **E3 – Almacenamiento y APIs**                | Integración con Virtuoso, AllegroGraph y Neo4j, APIs de acceso y extracción | 20%      |
| 4   | **E4 – IA y Validación Colaborativa**         | Pipeline de extracción y módulo de edición colaborativa                     | 20%      |
| 5   | **E5 – Frontend React y Gestión de Usuarios** | Interfaz web, registro, login y sistema de roles                            | 15%      |
| 6   | **E6 – Optimización y Despliegue Final**      | Seguridad, monitorización, pruebas de estrés y entrega final                | 15%      |

Cada hito cuenta con su propia **memoria técnica**, siguiendo una estructura estandarizada (E1, E2, ...).

---

## Despliegue y Entorno de Desarrollo

En esta versión inicial del OntoPortal, se utilizan los servicios que utiliza OntoPortal por defecto:

- **Ruby** (v3.1.6): Lenguaje de programación de la API y el frontend.
- **Sinatra** (v1.0): Framework web en Ruby para el backend.
- **Rails** (v7.2.2.1): Framework web en Ruby para el frontend.
- **JavaScript** para extender la interactividad y visualización en el frontend con **Node.js** (v20) para compilar ese código en JavaScript.
- **Docker** (v28.3.3): Para el despliegue de todos los servicios.
- Servicios:
  - **Redis** (v8): Base de datos en memoria para caché.
  - **Solr** (v8): Motor de búsqueda para indexación.
  - **Mgrep** (v0.0.2): Servicio de anotación y búsqueda de Ontoportal.
  - Bases de datos RDF. Se pueden utilizar dos opciones:
    - **4store** (v1.1.6): Base de datos de grafos RDF.
    - **AllegroGraph** (v8.1.0): Base de datos de grafos RDF.
  - **MySQL** (v8.0): Base de datos para licencias y usuarios.

### Requisitos Previos

- **Docker** 20.x.
- 8 GB de RAM recomendados

### Instalación Rápida (Infraestructura Base)

Clonar repositorio y descargar submódulos:

```bash
git clone https://github.com/proyectoTeresIA/portal

git submodule init
git submodule update
```

Configurar entorno

```bash
cp .env.sample .env
```

Editar variables de entorno según sea necesario. Para simplemente testear, no es necesario modificar nada.

Levantar servicios con la API usando 4store:

```bash
docker compose --profile 4store up -d
```

O levantar los servicios con la API usando AllegroGraph:

```bash
docker compose --profile agraph up -d
```

A continuación, hay que crear el usuario administrador para que la interfaz web funcione correctamente:

```bash
docker compose exec api bash -c "ruby create_admin_user.rb"
```

O, si se utiliza AllegroGraph:

```bash
docker compose exec api-agraph bash -c "ruby create_admin_user.rb"
```

En la consola aparecerá la API Key, que se debe copiar y pegar en el archivo `.env` como valor de `API_KEY`:

```bash
API_KEY=la_clave_api_generada
```

Una vez configurada la clave API, hay que reiniciar el servicio del frontend para que reconozca la nueva clave:

```bash
docker compose restart frontend-dev
```

Una vez levantados los servicios, se puede acceder a la interfaz web en:

- **Frontend**: http://localhost:3000
- **API**: http://localhost:9393

## Licencia

El proyecto se desarrolla siguiendo estándares abiertos y es compatible con las licencias de uso de los recursos integrados.

```

```
