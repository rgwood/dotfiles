Note: this is all from my initial experiments with DigitalOcean

#### Deploy+start containers or stop+remove them:
`docker-compose up -d`
`docker-compose down`

#### Backup database
Schema only
`docker exec scrapbook_db_server pg_dump scrapbook -U admin --schema-only > database/schema.sql`
Data only
`docker exec scrapbook_db_server pg_dump scrapbook -U admin --data-only > database/data.sql`

#### Copy static files to nginx serve directory

`docker cp LOCATION_ON_WORKSTATION/. scrapbook_nginx:/usr/share/nginx/html`
Ex:
`docker cp ~/source/next-tailwind/out/. scrapbook_nginx:/usr/share/nginx/html`

#### Open shell in a Docker container

`docker exec -it <container_name> sh`

#### Open psql in a Docker container

`docker exec -i scrapbook_db_server psql -U admin adventureworks`