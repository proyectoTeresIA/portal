# TeresIA OntoPortal - Guia Completa de Puesta en Marcha

Este repositorio levanta el portal OntoPortal adaptado para TeresIA con Docker Compose.

Stack principal:

- API (Sinatra + Unicorn)
- Frontend (Rails)
- Worker de tareas programadas (`ncbo-cron-worker`)
- Nginx (proxy y entrada publica)
- Fuseki (triplestore RDF)
- Solr, Redis, mgrep, MySQL y Memcached

## 1. Requisitos

- Docker Engine
- Docker Compose Plugin (`docker compose`)
- Recomendado: 8 GB RAM o mas

## 2. Clonar repositorio y submodulos

```bash
git clone https://github.com/proyectoTeresIA/portal
cd portal

git checkout ia
git submodule update --init --recursive
git submodule update --remote --merge
```

## 3. Preparar entorno

Copiar variables de ejemplo:

```bash
cp .env.sample .env
```

### 3.1 Ajuste de puertos y URLs

Edita `.env` y revisa, como minimo, estas variables:

- `PORTAL_HTTP_PORT=8080`
: Puerto del host para entrar al portal. Si 8080 esta ocupado, usa por ejemplo 8081.

- `PORTAL_BASE_PATH=/teresia-portal`
: Prefijo de ruta publicado por Nginx.

- `PUBLIC_UI_URL=http://localhost:8080`
: URL publica base del portal (sin el prefijo).

- `EXTERNAL_API_URL=http://localhost:8080/teresia-portal/api`
: URL publica de la API detras del proxy.

- `API_KEY=your_api_key_here`
: Se rellena despues de crear/consultar el usuario admin (paso 6).

- `ADMIN_PASSWORD=admin123`
: Password inicial para el usuario admin que crea el script.

Si cambias `PORTAL_HTTP_PORT`, ajusta tambien `PUBLIC_UI_URL` y `EXTERNAL_API_URL` al mismo puerto.

Ejemplo si usas 8081:

```env
PORTAL_HTTP_PORT=8081
PUBLIC_UI_URL=http://localhost:8081
EXTERNAL_API_URL=http://localhost:8081/teresia-portal/api
```

### 3.2 Volumen externo de MySQL (obligatorio)

Este proyecto define `portal_mysql_persistent` como volumen externo. Si es la primera vez en tu maquina, crealo:

```bash
docker volume create portal_mysql_persistent
```

## 4. Levantar el sistema

```bash
docker compose up -d
```

Comprobar estado:

```bash
docker compose ps
```

Todos los servicios deben aparecer en `Up` y, cuando aplique, en `healthy`.

## 5. Acceso inicial

- Portal UI: `http://localhost:8080/teresia-portal/`
- API publica (proxy): `http://localhost:8080/teresia-portal/api`

Si has cambiado el puerto, sustituye `8080` por tu valor en `PORTAL_HTTP_PORT`.

## 6. Crear usuario administrador y obtener API_KEY

El script de bootstrap esta en la raiz de `api` y crea (o recupera) el admin.

Ejecuta:

```bash
docker compose exec -w /srv/ontoportal/ontologies_api api ruby create_admin_user.rb
```

Este script:

- Crea el rol `ADMINISTRATOR` si no existe.
- Crea el usuario `admin` si no existe.
- Si ya existe, muestra igualmente su API key actual.

Salida esperada (resumen):

- `Admin user created successfully!` o `Admin user already exists!`
- `Username: admin`
- `API Key: <valor>`

## 7. Guardar la API_KEY en .env y reiniciar

1. Copia el valor mostrado en `API Key:`.
2. Sustituye en `.env`:

```env
API_KEY=<tu_api_key>
```

3. Reinicia servicios que consumen esa variable:

```bash
docker compose restart api frontend ncbo-cron-worker
```

## 8. Probar autenticacion contra la API

La API admite autenticacion por query param y por cabecera.

### 8.1 Con query param `apikey`

```bash
curl "http://localhost:8080/teresia-portal/api/ontologies?apikey=<tu_api_key>"
```

### 8.2 Con cabecera `Authorization`

```bash
curl "http://localhost:8080/teresia-portal/api/ontologies" \
  -H "Authorization: apikey token=<tu_api_key>"
```

Si has cambiado el puerto, usa el puerto configurado en `PORTAL_HTTP_PORT`.

## 9. Flujo rapido recomendado en una maquina nueva

```bash
git clone https://github.com/proyectoTeresIA/portal
cd portal
git checkout ia
git submodule update --init --recursive
cp .env.sample .env
docker volume create portal_mysql_persistent
docker compose up -d
docker compose exec -w /srv/ontoportal/ontologies_api api ruby create_admin_user.rb
# copiar API Key al .env
docker compose restart api frontend ncbo-cron-worker
```

## 10. Operaciones utiles

Ver logs en tiempo real:

```bash
docker compose logs -f
```

Parar todo:

```bash
docker compose down
```

Parar y borrar tambien volumenes (solo para reinicio completo de datos):

```bash
docker compose down -v
```

## 11. Despliegue detras de un Nginx externo

Si publicas bajo un dominio/ruta institucional (por ejemplo `https://dominio/teresia-portal`), ajusta en `.env`:

- `PORTAL_BASE_PATH=/teresia-portal`
- `PUBLIC_UI_URL=https://dominio`
- `EXTERNAL_API_URL=https://dominio/teresia-portal/api`
- `PORTAL_HTTP_PORT=8080` (o el puerto interno elegido)

Ejemplo de proxy en Nginx del host:

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

## 12. Incidencias criticas (produccion)

### 12.1 Error `ArgumentError in HomeController#index` (odd number of arguments for Hash)

Si aparece este error en `/teresia-portal/`, el frontend desplegado no tiene la correccion actual del controlador.

La version correcta usa `each_with_object({})` para construir `@ontologies_hash` en `frontend/app/controllers/home_controller.rb`.

Pasos de correccion en servidor:

```bash
cd /ruta/al/portal
git checkout ia
git pull --rebase
git submodule update --init --recursive
git submodule update --remote --merge

docker compose build frontend
docker compose up -d frontend nginx
docker compose logs --tail=120 frontend
```

Comprobacion esperada: `GET /teresia-portal/` responde `200` y ya no aparece `ArgumentError`.

### 12.2 Subida RDF falla en Fuseki (`Neither ?default nor ?graph`)

Para backend `fuseki`, la escritura RDF exige `?default` o `?graph` en la URL de `GOO_PATH_DATA`.

Asegura en `.env`:

```env
GOO_BACKEND_NAME=fuseki
GOO_HOST=fuseki-ut
GOO_PORT=3030
GOO_PATH_QUERY=/ontoportal_test/query
GOO_PATH_DATA=/ontoportal_test/data?default
GOO_PATH_UPDATE=/ontoportal_test/update
RACK_ENV=development
```

Importante: `api` y `ncbo-cron-worker` deben compartir el mismo `RACK_ENV` y apuntar al mismo Fuseki.

Aplicar cambios:

```bash
docker compose up -d --build api ncbo-cron-worker
docker compose restart api ncbo-cron-worker frontend
docker compose logs -f ncbo-cron-worker
```

Resultado esperado: la submission avanza a estado `RDF` y vuelven las pestanas de exploracion (por ejemplo, "Entrada Terminologica").

## 13. Configuracion de produccion validada (wiig)

Esta es la configuracion que se ha validado para despliegue en `https://wiig.dia.fi.upm.es/teresia-portal`.

### 13.1 Variables `.env` recomendadas

```env
RAILS_ENV=production
NODE_ENV=production
RACK_ENV=production

PUBLIC_UI_URL=https://wiig.dia.fi.upm.es
UI_URL=https://wiig.dia.fi.upm.es
PORTAL_BASE_PATH=/teresia-portal
UI_BASE_PATH=/teresia-portal
EXTERNAL_API_URL=https://wiig.dia.fi.upm.es/teresia-portal/api

PORTAL_HTTP_PORT=4080
GOO_BACKEND_NAME=fuseki
GOO_HOST=fuseki-ut
GOO_PORT=3030
GOO_PATH_QUERY=/ontoportal_test/query
GOO_PATH_DATA=/ontoportal_test/data?default
GOO_PATH_UPDATE=/ontoportal_test/update
```

Notas:

- `SECRET_KEY_BASE` debe ser real (no placeholder), por ejemplo generado con `openssl rand -hex 64`.
- `API_KEY` debe corresponder al usuario `admin` del entorno de servidor (no reutilizar la de local).

### 13.2 `docker-compose.yml` (claves)

Comprobar que no quedan hardcodeados valores de desarrollo:

- `x-frontend-app.build.args.RAILS_ENV: ${RAILS_ENV:-production}`
- `x-frontend-app.build.args.NODE_ENV: ${NODE_ENV:-production}`
- `x-frontend-app.environment.RAILS_ENV: ${RAILS_ENV:-production}`
- `x-api-app.environment.RACK_ENV: ${RACK_ENV:-development}`

### 13.3 Nginx externo (host wiig)

En el Nginx del host (el que publica HTTPS), reenviar siempre `https` al upstream para evitar perdida de sesion:

```nginx
location /teresia-portal/ {
  proxy_pass http://127.0.0.1:4080/teresia-portal/;
  proxy_set_header Host $host;
  proxy_set_header X-Forwarded-Host $host;
  proxy_set_header X-Forwarded-Port 443;
  proxy_set_header X-Forwarded-Proto https;
  proxy_set_header X-Forwarded-Ssl on;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

### 13.4 Despliegue/reinicio recomendado

```bash
git pull --rebase origin ia
git submodule update --init --recursive
docker compose up -d --build --force-recreate frontend api ncbo-cron-worker nginx
```

### 13.5 Verificaciones post-despliegue

```bash
docker compose exec frontend printenv RAILS_ENV
docker compose exec frontend bash -lc 'bundle exec rails runner "puts Rails.env; puts Rails.application.config.force_ssl"'
curl -I https://wiig.dia.fi.upm.es/teresia-portal/login
```

Esperado:

- `RAILS_ENV=production`
- `Rails.env` = `production`
- `force_ssl` = `true`
- no redirecciones a `http://...` tras login

### 13.6 Metricas de nuevas terminologias

Las metricas se calculan de forma asincrona en `ncbo-cron-worker`.

Comprobar estado:

```bash
curl -s "https://wiig.dia.fi.upm.es/teresia-portal/api/ontologies/AS/submissions/1?include=submissionStatus,metrics&apikey=<API_KEY>"
```

Si no aparece `METRICS`, forzar solo ese paso:

```bash
curl -X PUT "https://wiig.dia.fi.upm.es/teresia-portal/api/admin/ontologies/AS?actions=run_metrics&apikey=<API_KEY>"
docker compose logs -f ncbo-cron-worker | egrep -i "AS/submissions/1|METRICS|ERROR_METRICS|metrics_for_submission"
```
