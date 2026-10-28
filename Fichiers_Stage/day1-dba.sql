-- user dba

-- instance
select * from v$instance;

-- REDO LOGS
alter session set NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
select * from v$log;

-- vue statique: commence par DBA_, ALL_, USER_
select * from dba_users;


-- pour une base en mode CDB/PDB
-- user OS oracle
-- sqlplus / as sysdba  # connecté au CDB
SELECT SYS_CONTEXT('USERENV','CON_NAME') FROM dual;
select * from v$pdbs;  -- PDB$SEED
select * from dba_users order by username;  -- only current CDB/PDB pas de UMOVIE
select * from cdb_users order by username;  -- global : CDB + all PDB opened

alter session set container = dbmovie;
select * from dba_users order by username;


ALTER SESSION SET CONTAINER = CDB$ROOT;
select * from cdb_users order by username;

select user_id, username, common, con_id 
from cdb_users 
where username in ('SYS', 'SYSTEM', 'UMOVIE')
order by username;

-- le user proprietaire d'un schema avec le privilege RESOURCE n'inclut pas CREATE VIEW
grant create view to umovie;


