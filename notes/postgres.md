# Postgres Cheat Sheet

`psql|pgcli -d database_name -U user_name -h host_name`


## Install (Ubuntu)

`sudo apt-get install postgresql postgresql-contrib`

## Config location

On Ubuntu for pg 11: `/etc/postgresql/11/main/postgresql.conf`
Can check from psql: `SHOW config_file;`

## Enabling connections

Edit `pg_hba.conf` 

Allow username/pass logins from localhost and anything on the private network: 
```
host    all             all             127.0.0.1/32            md5
host    all             all             10.0.0.0/8              md5
host    all             all             192.168.0.0/16          md5
```

Reload after config file change: `systemctl reload postgresql`


Now, make Postgres listen for remote connections.

Edit `/var/lib/pgsql/data/postgresql.conf`, set `listen_addresses = '*'`

Restart: `systemctl restart postgresql`

View status and recent logs: `systemctl status postgresql`



## Passwords

Can give a Postgres user a password with `\password test_user` in `psql`

[PG passwords can be stored in ~/.pgpass](https://www.postgresql.org/docs/8.3/libpq-pgpass.html).

## Data locations

Tablespace: location on disk where data is stored. By default, `pg_default` and `pg_global` tablespaces are created in subfolders of `data_directory`.

```sql
select * from pg_tablespace;
```

```sql
--pg_default
select setting||'/base' from pg_settings where name='data_directory';
--pg_global
select setting||'/global' from pg_settings where name='data_directory';
```

## Partitioning

Kinda annoying that you have to manually define each partition. If you're partitioning by date, would be nice to have new partitions auto-generated.

CHECK constrains and partition bounds are separate things - but it can be useful to implement both.

## Permissioning

Postgres has a single permissioning object: `role`. `role`s encapsulate logins, users, and groups. Much simpler than SQL Server.

* Grant login permission: `CREATE ROLE Name WITH LOGIN`
* Grant database connect permission: `GRANT CONNECT ON DatabaseName TO RoleName`
* Add a role to another role: `GRANT Role1 to Role2`

View roles: `pg_roles` view;

## `psql` cheat sheet

* \d lists relations
    * \dt for just tables, \dv for just views, \df for functions...
    * can put a name pattern after \d, example: `\d prefix*`
    * add  to the metacommand + to get more info, including view definition

* \l lists databases

Start `psql` with `-E` to show the underlying queries it's using

## Case sensitivity

Postgres lower-cases unquoted identifiers. Use double quotes to preserve case.

Ex: `DROP ROLE publicReader` will attempt to drop a role named "publicreader", `DROP ROLE "publicReader";` correctly drops "public**R**eader"