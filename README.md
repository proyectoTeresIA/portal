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

## Despliegue y Entorno de Desarrollo (rama ia)

Desde la rama `ia` se usa un unico fichero `docker-compose.yml`, sin perfiles, con AllegroGraph como backend RDF y un proxy Nginx interno listo para trabajar bajo un prefijo de ruta.

Stack incluido:

- API (Sinatra + Unicorn)
- Frontend (Rails)
- Worker `ncbo-cron`
- Nginx
- AllegroGraph
- Solr
- Redis
- Mgrep
- MySQL
- Memcached

### Requisitos previos

- Docker Engine y Docker Compose Plugin
- 8 GB RAM recomendados

### Flujo recomendado (siempre en ia)

```bash
git clone https://github.com/proyectoTeresIA/portal
cd portal

git checkout ia
git submodule update --init --recursive
git submodule update --remote --merge
```

### Configuracion de entorno

```bash
cp .env.sample .env
```

Valores clave en `.env`:

- `API_KEY`: clave admin del portal
- `PORTAL_BASE_PATH`: prefijo de ruta (por defecto `/teresia-portal`)
- `PUBLIC_UI_URL`: URL publica base (por defecto `http://localhost`)
- `EXTERNAL_API_URL`: URL publica de API con prefijo (por defecto `http://localhost/teresia-portal/api`)
- `PORTAL_HTTP_PORT`: puerto HTTP expuesto por el contenedor Nginx (por defecto `80`)

### Arranque local

```bash
docker compose up -d
```

Crear/recuperar usuario admin y API key:

```bash
docker compose exec api bash -c "ruby create_admin_user.rb"
```

Copiar la API key mostrada por el script a `.env` y reiniciar frontend y API:

```bash
docker compose restart api frontend
```

Acceso local:

- Portal: http://localhost/teresia-portal/
- API publica (via proxy): http://localhost/teresia-portal/api

### Uso en servidor remoto detras de Nginx institucional

Si el Nginx de la universidad publica una ruta como `https://wiig.dia.fi.upm.es/teresia-portal`, mantener:

- `PORTAL_BASE_PATH=/teresia-portal`
- `PUBLIC_UI_URL=https://wiig.dia.fi.upm.es`
- `EXTERNAL_API_URL=https://wiig.dia.fi.upm.es/teresia-portal/api`
- `PORTAL_HTTP_PORT=8080` (recomendado para no ocupar el 80 del host)

Ejemplo de bloque en Nginx del host:

```nginx
location /teresia-portal/ {
      proxy_pass http://127.0.0.1:8080/teresia-portal/;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}

location /teresia-portal/api/ {
      proxy_pass http://127.0.0.1:8080/teresia-portal/api/;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

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

## Licencia

El proyecto se desarrolla siguiendo estándares abiertos y es compatible con las licencias de uso de los recursos integrados.

```

```
