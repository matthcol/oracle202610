# tags:
# - latest-26
# - latest-19
docker login container-registry.oracle.com
docker compose up -d
docker compose exec -u root oradb chown -R oracle:oinstall /backup