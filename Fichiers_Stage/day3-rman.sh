# user OS oracle ou utiliser les credentials

# differentes façons de démarrer RMAN
export NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
rman target /        -- as sysdba
rman target SYS      -- as sysdba
rman target SYSTEM   -- as sysdba
rman
    connect target /

    # --- configurer le nom des fichiers de backup ---

    # database + archivelog (même channel disque, donc même format pour les deux)
    CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/orabackup/fast_recovery_area/%d/database_%T_%U.bkp';

    # %d = nom de la base, %T = date (YYYYMMDD), %U = nom unique généré par RMAN, %F = nom imposé par Oracle pour l'autobackup (c-IDCONTROLFILE-YYYYMMDD-XX)

    # spfile + controlfile : via l'autobackup (nom imposé par Oracle : %F)
    CONFIGURE CONTROLFILE AUTOBACKUP ON;
    CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/orabackup/fast_recovery_area/%d/init_%F';

    backup database;
    backup database plus archivelog;
    backup archivelog all;

    list backup;
    list backup of database;
    list backup of archivelog all;
    -- backup archivelog plusieurs par jour en faisant le menage du dossier archivelog
    BACKUP ARCHIVELOG ALL DELETE ALL INPUT;
    list archivelog all;
    
    list backup of archivelog from time "to_date('2026-10-28 10:45:00','YYYY-MM-DD HH24:MI:SS')";
    list backup of archivelog from time '2026-10-28 10:45:00'; -- TODO ???
    list backup of spfile;
    list backup of controlfile;

    -- parametrage
    show all;
    show RETENTION POLICY; -- 1

    # 2 modeles de retention
    CONFIGURE RETENTION POLICY TO REDUNDANCY 1;  # nb de piece backup complet
    CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS; # nb de jours

    REPORT OBSOLETE;
    DELETE OBSOLETE;
    DELETE FORCE NOPROMPT OBSOLETE;

    -- --- restauration incomplète (point-in-time recovery) ---
    -- voir script-restore.until-time.rman et script-restore.until-scn.rman

    

    -- exemple restore
    restore database;
    recover database;


# jouer un script RMAN avec config + backup + nettoyage
# + taches planifiees OS en tant que oracle ou user de service
rman target / @script-sauvegarde-complet.rman
rman target / @script-sauvegarde-archivelog.rman
rman target / @script-restore-database-full.rman
rman target / @script-restore.until-time.rman
rman target / @script-restore.until-scn.rman



