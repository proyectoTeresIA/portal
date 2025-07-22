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

| Mes | Hito | Entregable | % Avance |
|-----|------|------------|----------|
| 1 | **E1 – Infraestructura** | Despliegue de OntoPortal, arquitectura técnica, CI/CD | 10% |
| 2 | **E2 – Catálogo de Terminologías** | OntoPortal adaptado, metabuscador funcional, ingesta RDF/CSV | 20% |
| 3 | **E3 – Almacenamiento y APIs** | Integración con Virtuoso, AllegroGraph y Neo4j, APIs de acceso y extracción | 20% |
| 4 | **E4 – IA y Validación Colaborativa** | Pipeline de extracción y módulo de edición colaborativa | 20% |
| 5 | **E5 – Frontend React y Gestión de Usuarios** | Interfaz web, registro, login y sistema de roles | 15% |
| 6 | **E6 – Optimización y Despliegue Final** | Seguridad, monitorización, pruebas de estrés y entrega final | 15% |

Cada hito cuenta con su propia **memoria técnica**, siguiendo una estructura estandarizada (E1, E2, ...).

---

## Despliegue y Entorno de Desarrollo

### Requisitos Previos

- **Docker** 20.x y **Docker Compose** 2.x  
- **Node.js** 18.x para el frontend  
- **Java** 11+ y **SpringBoot** (backend)  
- 8 GB de RAM recomendados

### Instalación Rápida (Infraestructura Base)

```bash
# Clonar repositorio
git clone https://github.com/ontoportal/ontoportal_docker.git
cd ontoportal_docker

# Configurar entorno
cp .env.sample .env
# Editar variables: MYSQL, VIRTUOSO, host, etc.

# Levantar servicios
docker compose up -d
````

El acceso inicial se realiza en: http://localhost:8080

## Licencia

El proyecto se desarrolla siguiendo estándares abiertos y es compatible con las licencias de uso de los recursos integrados.