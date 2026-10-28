# Oracle Database
Historique Oracle:
Historique standard SQL
## Documentation
### Portail
- Accueil :
https://docs.oracle.com/en/database/oracle/oracle-database/19/index.html
- Role developer : 
https://docs.oracle.com/en/database/oracle/oracle-database/19/development.html
- Role Admin :
https://docs.oracle.com/en/database/oracle/oracle-database/19/administration.html
### Books
- SQL Reference : DDL, DML, fonctions, privileges, transactions
    * https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/index.html
- PL/SQL Reference(s) : langage + packages et types fournis par Oracle
    * https://docs.oracle.com/en/database/oracle/oracle-database/19/lnpls/index.html
    * https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/index.html
- Database Reference: paramètres initiaux, vues statiques et dynamiques
    * https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/index.html
- Guide administrateur
    * https://docs.oracle.com/en/database/oracle/oracle-database/19/admin/index.html
- Backup/Recovery : RMAN
    * https://docs.oracle.com/en/database/oracle/oracle-database/19/rcmrf/index.html
- Utilities : dump (exp/imp, expdp/impdp), sql*loader 
    * https://docs.oracle.com/en/database/oracle/oracle-database/19/sutil/index.html

## Services
2 services principaux: 
- listener : gère les connexions
- database : gère l'instance

### Linux (systemd)
```sh
systemctl status|start|stop|restart oracle-listener
systemctl status|start|stop|restart oracle-database
```

### Windows
```sh
sc query OracleServiceORA19
# or
Get-Service OracleServiceORA19

net start OracleServiceORA19
# or
Start-Service OracleServiceORA19

net stop OracleServiceORA19
# or
Stop-Service OracleServiceORA19
```

## Conteneur OS (Docker, Podman, containerd)
Voir fichiers de configuration du répertoire `docker`

## Différentes Versions et Liceces
- EE : Enterprise Edition
- SE : Standard Edition (même logiciel que EE mais bridé perf)
- XE/Free : XE = Express Edition (10 => ~21) devient 23/26 Free

## Administration par la pratique
Voir scripts `day*.sql|sh` du dossier `Fichiers_Stage`

TODO: intégrer les fichiers du PC stagiaire