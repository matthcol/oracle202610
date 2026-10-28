-- user dba : system (sauf mention)

-- usage legacy du type date : Y-M-D H:M:S
alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
alter session set nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS';


select 
    GROUP#,
    SEQUENCE#,
    status,
    FIRST_CHANGE#,
    NEXT_CHANGE#,
    FIRST_TIME,
    NEXT_TIME
from v$log;

select 
    SCN_TO_TIMESTAMP(2813413)  as horodatage_scn -- 2026-10-28 03:01:00
    , TIMESTAMP_TO_SCN('2026-10-28 02:01:00') as scn-- 2796362
from dual;

select current_scn from v$database;  -- 2868547


-- emplacement des redo logs
select * from V$LOGFILE;
select * from V$LOGHIST;

ALTER DATABASE
ADD LOGFILE GROUP 4 ('/oradata/ORA19/redo04.log')
SIZE 4M;
ALTER DATABASE
ADD LOGFILE GROUP 5 ('/oradata/ORA19/redo05.log')
SIZE 4M;
ALTER DATABASE
ADD LOGFILE GROUP 6 ('/oradata/ORA19/redo06.log')
SIZE 4M;

select * from v$log;
select * from V$LOGFILE;

alter system switch LOGFILE; -- X2
select * from v$log;

ALTER DATABASE
DROP LOGFILE GROUP 1
;

ALTER DATABASE
DROP LOGFILE GROUP 2
;

select * from v$log;

-- reboot pour rendre inactif le dernier à 200M
ALTER DATABASE
DROP LOGFILE GROUP 3
;

select * from v$log;

-- en local avec sqlplus / as sysdba
shutdown immediate
-- supprimer un control01
startup -- => echouer au moment du mount
select * from v$instance;


select  STATUS from v$instance;  -- started, mounted, open

-- summary startup
startup nomount
startup mount
-- startup ... restriction (readonly) 
startup  -- normal

-- si started dans un etat dégradé
alter database mount;
alter database open;

select  STATUS from v$instance;

select current_scn from v$database;  -- 2868547 => 2871565

-- changer le statut du mode archivelog
-- * archivelog ON : archivage des REDO*.log + backup RMAN à chaud
-- * archivelog OFF : pas d'archivage + backup RMAN à froid
shutdown immediate
startup mount
alter database archivelog;
-- alter database noarchivelog;
alter database open;

select * from v$archived_log;
alter system switch LOGFILE; 


select * from v$log;

select * from dba_directories;

-- spfile / control file
show parameter control
-- control_files                  string  /oradata/ORA19/control01.ctl, /orabackup/fast_recovery_area/ORA19/control02.ctl 
alter system set control_files = '/oradata/ORA19/control01.ctl', '/orabackup/other_place/ORA19/control02.ctl' scope=SPFILE;
alter system set control_files = '/oradata/ORA19/control01.ctl', '/orabackup/fast_recovery_area/ORA19/control02.ctl' scope=SPFILE;
-- parametres: scope BOTH (les 2), MEMORY (instance en cours), SPFILE (prochain boot)

show parameter log_archive_dest -- specifier l'emplacement des archives logs si il ny a pas de fast recovery area ou pour doubler cet archivage
show parameter recove
-- db_recovery_file_dest         string      /orabackup/fast_recovery_area 
-- db_recovery_file_dest_size    big integer 5G    

show parameter pfile
-- spfile string /oracle/product/19.3.0/dbhome_1/dbs/spfileora19.ora 

-- spfile (binaire) :  spfileora19.ora
-- pfile (texte) : initora19.ora

create pfile = '/oracle/product/19.3.0/dbhome_1/dbs/initora19.ora' from spfile;
-- edit pfile
create spfile = '/oracle/product/19.3.0/dbhome_1/dbs/spfileora19_new.ora' from pfile = '/oracle/product/19.3.0/dbhome_1/dbs/initora19.ora';


-- stats / supervision / fragmentation

-- 1 - statistiques : 
--   * stat à jour + bons index => choix du plan execution => queries efficaces

-- job qui tourne toutes les nuits pour rafraichir les stats : auto optimizer stats job

-- qqs stats sur la vue d'1 table : num_rows
select *  from DBA_TABLES where owner = 'UMOVIE' and table_name = 'MOVIE';

-- en // : bcp d'inserts
select *  from DBA_TABLES where owner = 'UMOVIE' and table_name = 'MOVIE';
-- => stats n'est pas encore à jour

-- rafraichir manuellement les stats
-- GATHER_*_STATS : grain database, schema, table/index
EXEC DBMS_STATS.GATHER_TABLE_STATS(ownname => 'UMOVIE', tabname => 'MOVIE');
select *  from DBA_TABLES where owner = 'UMOVIE' and table_name = 'MOVIE'; -- numrows updated : 111188
select num_rows, LAST_ANALYZED  from DBA_TABLES where owner = 'UMOVIE' and table_name = 'MOVIE';

select count(*) from umovie.movie; -- 111188

-- voir les options d'échantillonnage
EXEC DBMS_STATS.GATHER_TABLE_STATS(ownname => 'UMOVIE', tabname => 'MOVIE', estimate_percent => 0.001);
EXEC DBMS_STATS.GATHER_TABLE_STATS(ownname => 'UMOVIE', tabname => 'MOVIE', estimate_percent => 1);
-- exemple de stat par colonne
select * from DBA_TAB_COL_STATISTICS where owner = 'UMOVIE' and table_name = 'MOVIE';
-- NUM_DISTINCT / (NUM_ROWS - NUM_NULLS) => efficacité du BTREE

-- TODO: stale factor
-- select STALE_STATS  from DBA_TABLES where owner = 'UMOVIE' and table_name = 'MOVIE';


-- ***********************************
-- fragmentation des tables et indexes

-- Oracle 10+ : management auto des disques : ASSM

-- Sans ASSM => COALESCE
ALTER TABLESPACE users COALESCE;

-- Autre approche par table ou index
ALTER TABLE umovie.movie MOVE;
ALTER INDEX umovie.pk_movie REBUILD;
-- opt: change TS + DF


-- session / SQL
select * from v$sql;

SELECT sql_id, child_number, executions, buffer_gets, disk_reads,
       round(elapsed_time/1e6,2) AS elapsed_sec,
       round(cpu_time/1e6,2)     AS cpu_sec,
       sql_text
FROM   v$sql
ORDER  BY elapsed_time DESC;

-- pour voir les parametres binded
-- * v$sql_bind_capture
-- * outil monitoring : DBMS_MONITOR


select * from v$session where username is not null;

select * from v$session where username = 'UMOVIE';

select * from v$lock;

alter system kill session '34,36301' immediate;
select * from v$session where username = 'UMOVIE';

-- reglages : sqlnet / listener / tnsnames
-- ls /oracle/product/19.3.0/dbhome_1/network/admin/

-- outils : dbca (install), netca (config tnsnames, listener)

-- logs (traces)
/oracle/diag
    tnslsnr/orarocky19/listener/trace/listener.log 
    tail rdbms/ora19/ora19/trace/alert_ora19.log 

