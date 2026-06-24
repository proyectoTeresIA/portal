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
docker compose restart frontend # Si se usa 4store
# o
docker compose restart frontend-agraph # Si se usa AllegroGraph
```

Una vez levantados los servicios, se puede acceder a la interfaz web en:

- **Frontend**: http://localhost:3000
- **API**: http://localhost:9393

## Cronjobs y tareas programadas

El despliegue ejecuta tanto tareas programadas a nivel de host como varios hilos/jobs internos dentro del servicio `ncbo-cron-worker`. A continuación están las tareas relevantes, su cron por defecto, su propósito y dónde se configuran:

| Tarea                               |                                    Frecuencia por defecto | Qué hace                                                                                                                                                                        | Dónde se configura / log                                                                                                          |
| ----------------------------------- | --------------------------------------------------------: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Healthcheck del anotador (host)     |                              `0 */4 * * *` (cada 4 horas) | Comprueba Redis vs `dictionary.txt` y mgrep; cuando detecta caché vacía o incompleta invoca la regeneración con `api/scripts/regenerate_annotator_cache.sh` y reinicia `mgrep`. | Host crontab: `/var/spool/cron/crontabs/root` → `api/scripts/annotator_healthcheck.sh`. Log: `/var/log/annotator_healthcheck.log` |
| ncbo_cron — Process queue (parsing) | `30 */4 * * *` (valor por defecto global `cron_schedule`) | Revisa la cola de envíos y procesa (parsea) submissions en background (principalmente `OntologySubmissionParser`).                                                              | `ncbo_cron` opciones / `lib/ncbo_cron/config.rb`. Log: `ontologies_api/log/scheduler.log`                                         |
| ncbo_cron — Pull (external pulls)   |                                             `00 18 * * *` | Pulls externos (p. ej. UMLS) según configuración.                                                                                                                               | `cron.pull_schedule` en `lib/ncbo_cron/config.rb`                                                                                 |
| ncbo_cron — Flush (archive cleanup) |                                             `00 22 * * 2` | Limpieza periódica (elimina grafos de clases archivadas).                                                                                                                       | `cron_flush` en `lib/ncbo_cron/config.rb`                                                                                         |
| ncbo_cron — Warmup queries (warmq)  |                                            `00 */3 * * *` | Ejecuta consultas de warm-up para mantener caches/queries calientes.                                                                                                            | `cron_warmq` en `lib/ncbo_cron/config.rb`                                                                                         |
| ncbo_cron — Mapping counts          |                                    `30 0 * * 6` (semanal) | Calcula estadísticas de mappings (conteos).                                                                                                                                     | `cron_mapping_counts` en `lib/ncbo_cron/config.rb`                                                                                |
| ncbo_cron — Ontology analytics      |                                    `15 0 * * 1` (semanal) | Refresca métricas/analíticas relacionadas con ontologías (GA4).                                                                                                                 | `cron_ontology_analytics` en `lib/ncbo_cron/config.rb`                                                                            |
| ncbo_cron — Cloudflare analytics    |                                      `0 1 * * *` (diario) | Recolecta/actualiza métricas de Cloudflare si está habilitado.                                                                                                                  | `cron_cloudflare_analytics` en `lib/ncbo_cron/config.rb`                                                                          |
| ncbo_cron — Ontology rank           |                                     `0 4 * * 1` (semanal) | Genera/actualiza ranking de ontologías.                                                                                                                                         | `cron_ontology_rank` en `lib/ncbo_cron/config.rb`                                                                                 |
| ncbo_cron — Ontologies report       |                                     `30 1 * * *` (diario) | Genera el informe JSON de ontologías (`reports/ontologies_report.json`).                                                                                                        | `cron_ontologies_report` en `lib/ncbo_cron/config.rb`                                                                             |
| ncbo_cron — Index synchronizer      |                              `30 3 */2 * *` (cada 2 días) | Sincroniza índices con Solr para búsquedas.                                                                                                                                     | `cron_index_synchronizer` en `lib/ncbo_cron/config.rb`                                                                            |
| ncbo_cron — Spam deletion           |                                     `30 2 * * *` (diario) | Borrado periódico de contenidos marcados como SPAM (opcional).                                                                                                                  | `cron_spam_deletion` en `lib/ncbo_cron/config.rb`                                                                                 |
| ncbo_cron — Update check            |                                     `00 3 * * *` (diario) | Comprueba disponibilidad de actualizaciones del appliance/ontologies.                                                                                                           | `cron_update_check` en `lib/ncbo_cron/config.rb`                                                                                  |
| ncbo_cron — OBO Foundry sync        |                           `0 8 * * 1,2,3,4,5` (L–V 08:00) | Sincronización / reporte con OBO Foundry (opcional).                                                                                                                            | `cron_obofoundry_sync` en `lib/ncbo_cron/config.rb`                                                                               |
| ncbo_cron — Dictionary generation   |                                     `30 3 * * *` (diario) | Regenera `mgrep` `dictionary.txt` desde la caché de Annotator.                                                                                                                  | `cron_dictionary_generation_cron_job` (configurable en `api/config/environments/production.rb`)                                   |

Notas rápidas:

- Todos los jobs internos se gestionan desde `ncbo_cron` y sus defaults están en `lib/ncbo_cron/config.rb` del paquete `ncbo_cron`.
- La mayoría de jobs se ejecutan con `NcboCron::Scheduler.scheduled_locking_job` y escriben trazas en `ontologies_api/log/scheduler.log`.
- Las opciones específicas pueden ajustarse pasando variables de configuración al iniciar `ncbo_cron` (ver `api/scripts/start-ncbo-cron.sh`).

## Backups de 4store y Solr

Para proteger el triplestore y los índices de búsqueda, el repositorio incluye el script `scripts/backup_4store_solr.sh`.

Características:

- Para brevemente `ncbo-cron-worker`, `frontend`, `api`, `4store-ut` y `solr-ut` para generar una copia consistente.
- Guarda `4store.tgz` y `solr.tgz` bajo `BACKUP_DIR/<timestamp>/`.
- Elimina automáticamente backups más antiguos que `BACKUP_RETENTION_DAYS`.
- Comprueba primero si `ncbo-cron-worker` parece estar ocioso con `scripts/check_ncbo_cron_idle.sh`.

Variables configurables en `.env`:

- `BACKUP_DIR=/root/backup_ontoportal`
- `BACKUP_RETENTION_DAYS=15`
- `BACKUP_RETENTION_COUNT=0` (si es mayor que 0, tiene prioridad y conserva solo los últimos N backups)
- `IDLE_WINDOW_MINUTES=5`
- `ALLOW_BUSY_WORKER=false`

Ejecución manual:

```bash
./scripts/backup_4store_solr.sh
```

Chequeo manual del worker antes del backup:

```bash
./scripts/check_ncbo_cron_idle.sh
```

Si el worker está activo, el script devolverá salida no nula. En ese caso, espera a que termine o lanza el backup con `ALLOW_BUSY_WORKER=true` solo si aceptas una ventana ligeramente menos segura.

Ejemplo de cron semanal (domingo a las 00:00):

```bash
0 0 * * 0 cd /app/portal && ./scripts/backup_4store_solr.sh >> /var/log/ontoportal-backup.log 2>&1
```

Para conservar aproximadamente 2 meses con backup semanal, configura:

```dotenv
BACKUP_RETENTION_COUNT=8
BACKUP_RETENTION_DAYS=0
```

Comprobación recomendada antes de lanzar el backup:

```bash
docker compose -f docker-compose.production.yml --profile 4store logs --since=5m ncbo-cron-worker | tail -80
```

Si en los últimos minutos no aparecen mensajes de procesamiento activo de submissions, y la API devuelve pocos o ningún cambio en `/submissions`, el worker está razonablemente ocioso para una parada corta. En situaciones críticas, la opción más segura sigue siendo parar brevemente `ncbo-cron-worker` antes del backup consistente.

Restauración manual desde un backup existente:

```bash
./scripts/restore_4store_solr.sh 20260623-033000
```

También acepta una ruta absoluta al directorio del backup:

```bash
./scripts/restore_4store_solr.sh /root/backup_ontoportal/20260623-033000
```

## Licencia

El proyecto se desarrolla siguiendo estándares abiertos y es compatible con las licencias de uso de los recursos integrados.

```

```
