-- user dba : system

grant create public synonym to umovie;

-- utilise le synonyme publique
select * from person;


drop user fan80s cascade;
create user fan80s identified by password;
-- privilege systeme
grant connect to fan80s;
-- privileges objets
grant select on umovie.person to fan80s;
create synonym fan80s.movie for umovie.v_movie1980s;
grant select on umovie.v_movie1980s to fan80s;

-- *** vues statiques sur les privileges (Oracle 19) ***

-- privileges systeme (ex: CREATE SESSION, ...)
select * from dba_sys_privs order by grantee;
select * from dba_sys_privs where grantee IN ('FAN80S', 'UMOVIE');
select * from user_sys_privs;   -- privileges systeme du user connecte
select * from session_privs;    -- privileges systeme actifs dans la session (roles non actives exclus)

-- roles attribues a un user/role
select * from dba_role_privs where grantee IN ('FAN80S', 'UMOVIE');
select * from user_role_privs;  -- roles du user connecte

-- contenu d'un role : privileges systeme et objets qu'il porte
select * from role_sys_privs where role IN ('DBA');
select * from role_sys_privs where role IN ('CONNECT', 'RESOURCE'); -- ???
select * from role_tab_privs where role IN ('CONNECT', 'RESOURCE');

-- liste des roles existants dans la base
select * from dba_roles;

-- privileges sur les objets (tables, vues, ...)
select * from dba_tab_privs where grantee = 'FAN80S';
select * from user_tab_privs;   -- objets accessibles au user connecte (recus directement ou via ALL_)
select * from all_tab_privs;    -- idem, limite aux privileges du user courant (y compris public)

-- privileges colonne par colonne (ex: grant select(col) on ...)
select * from dba_col_privs where grantee = 'FAN80S';
select * from user_col_privs;

-- *************************
--     atelier roles
-- *************************
grant create role to umovie;

-- TODO : recuperer le SQL stagiaire


-- DB Parameters
show parameter
show parameter

-- *************************
--     atelier stockage
-- *************************
select * from DBA_TABLESPACES;

create user critic identified by password;
grant connect, resource to critic;
select * from dba_users where username in ('SYS', 'UMOVIE', 'CRITIC');
-- SYS => tablespace SYSTEM
-- UMOVIE => tablespace DATA_MOVIE (custom)
-- CRITIC => tablespace USERS (default)

SELECT *
FROM database_properties;

-- settings tablespace au niveau base => reprise par defaut sur tout nouveau user => repris par defaut sur tte nouvelle table ou index
SELECT *
FROM database_properties
where property_name like '%TABLESPACE%'
;


create table critic.movie_critic (
    id integer constraint pk_movie_critic primary key,
    content varchar2(4000) not null
);
select * from dba_tables where owner = 'CRITIC'; -- tablespace USERS (default de cet utilisateur = deafault base)
select * from dba_tables where owner = 'UMOVIE'; -- tablespace DATA_MOVIE (default de cet utilisateur)

-- TODO LATER: specifier le TS au niveau d'une table et/ou index

select * from DBA_DATA_FILES;

drop tablespace data_critic;  -- + rm 
create tablespace data_critic 
    datafile '/oradata/ORA19/data_critic01.dbf' 
    size 500M 
    autoextend on
;
select 
    FILE_NAME,
    FILE_ID,
    TABLESPACE_NAME,
    AUTOEXTENSIBLE,
    BYTES,
    MAXBYTES,   -- 34359721984 ~32G
    ROUND(BYTES / MAXBYTES * 100, 2) as occupied_p,
    ROUND((MAXBYTES - BYTES) / MAXBYTES * 100, 2) as free_p
from DBA_DATA_FILES;

select 32*1024*1024*1024 from dual;  -- 32G = 34359738368

alter tablespace data_critic add datafile '/oradata/ORA19/data_critic02.dbf' size 500M; -- !! rajouter AUTOEXTEND

select 
    FILE_NAME,
    FILE_ID,
    TABLESPACE_NAME,
    AUTOEXTENSIBLE,
    BYTES,
    MAXBYTES
    --,   -- 34359721984 ~32G
    --ROUND(BYTES / MAXBYTES * 100, 2) as occupied_p,
    --ROUND((MAXBYTES - BYTES) / MAXBYTES * 100, 2) as free_p
from DBA_DATA_FILES;

-- designation d'un datafile par son chemin ou son numero
alter database datafile 9 AUTOEXTEND on;  -- + MAX à 32G


ALTER TABLE CRITIC.MOVIE_CRITIC MOVE 
TABLESPACE DATA_CRITIC;
select * from dba_tables where owner = 'CRITIC';
select * from dba_indexes where owner = 'CRITIC';

create tablespace index_critic 
    datafile '/oradata/ORA19/index_critic01.dbf' 
    size 500M 
    autoextend on
;
ALTER INDEX CRITIC.PK_MOVIE_CRITIC REBUILD TABLESPACE INDEX_CRITIC;
select * from dba_indexes where owner = 'CRITIC';

-- faire du custom sur le stockage d'une table et/ou index
create tablespace data_bigtable 
    datafile '/oradata/ORA19/data_bigtable01.dbf' 
    size 500M 
    autoextend on
;
create tablespace index_bigtable
    datafile '/oradata/ORA19/index_bigtable01.dbf' 
    size 500M 
    autoextend on
;

-- big table (pas forcement une bonne idee !)
create table umovie.bo (
    id integer,
    video blob,
    last_updated timestamp
) 
tablespace data_bigtable
-- lob (video) store as (tablespace data_bigtable)  -- data + index interne des LOB sont colocalisés
;

alter table umovie.bo add constraint pk_bo primary key(id) using index tablespace index_bigtable;

create index umovie.idx_bo_last_updated on umovie.bo(last_updated) tablespace index_bigtable;

-- ouvrir les droits sur les tablespaces
alter user umovie quota unlimited on data_bigtable;
alter user umovie quota unlimited on index_bigtable;
alter user critic quota unlimited on data_critic;
alter user critic quota unlimited on index_critic;



-- simulation d'une ecriture d'un blob
declare
    v_blob umovie.bo.video%type;
begin
    insert into umovie.bo (id, video, last_updated)
    values (1, empty_blob(), systimestamp)
    returning video into v_blob;

    dbms_lob.writeappend(
        v_blob,
        20,
        utl_raw.cast_to_raw(rpad('X', 20, 'X'))
    );

    commit;
exception
    when dup_val_on_index then
        rollback;
        dbms_output.put_line('id deja existant : insertion annulee');
    when others then
        rollback;
        dbms_output.put_line('erreur ecriture blob : ' || sqlerrm);
        raise;
end;
/

select id, dbms_lob.getlength(video) as video_size, last_updated
from umovie.bo;

select owner, table_name as object_name, 'table' as object_type, TABLESPACE_NAME from dba_tables where owner = 'UMOVIE'
UNION
select owner, index_name as object_name, 'index' as object_type, TABLESPACE_NAME from dba_indexes where owner = 'UMOVIE'
ORDER BY object_type, object_name;
-- NB: on voit l'index interne sur la gestion des LOBS: SYS_IL0000073258C00002$$

-- Segments : partie d'un TS (donc DF) pour 1 table ou 1 index ou 1 LOB ou 1 index de LOB
select * from DBA_SEGMENTS;
select * from DBA_SEGMENTS WHERE owner = 'UMOVIE';

select SUM(BYTES) as schema_size, SUM(EXTENTS) as extent_count from DBA_SEGMENTS WHERE owner = 'UMOVIE';
select SUM(BYTES) as ts_real_size, SUM(EXTENTS) as extent_count from DBA_SEGMENTS WHERE TABLESPACE_NAME = 'DATA_MOVIE';
select TABLESPACE_NAME, SUM(BYTES) / 1024 / 1024 as ts_real_size_mb, SUM(EXTENTS) as extent_count from DBA_SEGMENTS GROUP BY TABLESPACE_NAME;

select * from DBA_SEGMENTS WHERE owner = 'UMOVIE' and segment_name = 'MOVIE';
-- 1 extent = 1 macro bloc : dans cette base 1 extent = 65K, 1 block = 8K
select * from DBA_EXTENTS WHERE owner = 'UMOVIE' and segment_name = 'MOVIE';


select 
    FILE_NAME,
    FILE_ID,
    TABLESPACE_NAME,
    AUTOEXTENSIBLE,
    BYTES,
    MAXBYTES,   -- 34359721984 ~32G
    ROUND(BYTES / MAXBYTES * 100, 2) as occupied_p,
    ROUND((MAXBYTES - BYTES) / MAXBYTES * 100, 2) as free_p
from DBA_DATA_FILES;

select 
    TABLESPACE_NAME,
    listagg(FILE_NAME, ', ') as file_names,
    listagg(FILE_ID, ', ') as file_ids,
    MIN(AUTOEXTENSIBLE) AS AUTOEXTENSIBLE,
    SUM(BYTES) as bytes,
    SUM(MAXBYTES) AS MAXBYTES,
    ROUND(SUM(BYTES) / SUM(MAXBYTES) * 100, 2) as occupied_p,
    ROUND((SUM(MAXBYTES) - SUM(BYTES)) / SUM(MAXBYTES) * 100, 2) as free_p
from DBA_DATA_FILES
group by TABLESPACE_NAME;





















