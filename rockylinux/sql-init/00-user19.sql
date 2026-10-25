-- run this script as DBA

set termout off
column data_dir new_value data_dir
SELECT substr(file_name, 1, instr(file_name, '/', -1)) AS data_dir
FROM dba_data_files
WHERE tablespace_name = 'USERS';
set termout on

CREATE TABLESPACE data_movie
	DATAFILE '&data_dir.data_movie01.dbf' SIZE 200M AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED;

CREATE TABLESPACE idx_movie
	DATAFILE '&data_dir.idx_movie01.dbf' SIZE 100M AUTOEXTEND ON NEXT 20M MAXSIZE UNLIMITED;

create user umovie identified by password
	default tablespace data_movie
	temporary tablespace temp;

grant connect, resource to umovie;
alter user umovie quota unlimited on data_movie;
alter user umovie quota unlimited on idx_movie;
