-- user métier umovie (propriétaire tables métiers)

-- *************************************************
-- Quelques vues statiques (dictionnaire de données)
-- *************************************************

-- tables dont je suis le proprietaire
select * from user_tables;

-- mes tables + celles que je peux voir
select * from all_tables;

-- interdit
select * from dba_tables;
select * from sys.dba_tables;


describe movie;

-- sqlplus display
set linesize 255
set pagesize 999
column table_name format A15
column TABLESPACE_NAME format A15

select table_name, TABLESPACE_NAME, NUM_ROWS 
from user_tables;


insert into movie (title, year) values ('The Odyssey', 2026);
commit;


-- **********************************************
--           objets du schema umovie
-- **********************************************

select title, year
from MOVIE           -- table du schema courant = user umovie
where YEAR = 1984;

select title, year
from UMOVIE.MOVIE    -- schema explicite 
where YEAR = 1984;

create view v_movie1984 as (
    select title, year, duration, director_id
    from MOVIE       
    where YEAR = 1984
);

select * from v_movie1984;

-- indexes
select * from person where id = 142; -- explain plan => pk_person
select * from person where name = 'Clint Eastwood';  -- pas d'index sur name =>  TABLE ACCESS FULL

create index idx_name on person(name);
select * from person where name = 'Clint Eastwood';  -- explain plan => idx_person

select
    count(distinct id) / count(id) as selectivity_id,
    count(distinct name) / count(name) as selectivity_name
from person;  
-- 1	0.9926886744949545811597413845193256661766

select
    count(distinct id) / count(id) as selectivity_id,
    count(distinct title) / count(title) as selectivity_title,
    count(distinct year) / count(year) as selectivity_year
from movie;  

select * from person where lower(name) = 'clint eastwood'; -- n-utilise pas idx_person_name
create index idx_name_lo on person(lower(name));
select * from person where lower(name) = 'clint eastwood'; -- OK : idx_name_lo
select * from person where lower(name) like 'clint %'; -- OK : idx_name_lo
select * from person where lower(name) like '%eastwood'; -- KO : pas d'index

-- see also : index FTS (Full Text Search)

select 
    m.title,
    m.year,
    d.name
from 
    movie m 
    left join person d on m.DIRECTOR_ID = d.ID  -- pour aller chercher le realisateur => passe par l'index pk_person
where 
    m.YEAR = 1984  -- TODO:  1 index efficace
;

select 
    m.title,
    m.year,
    d.name
from 
    movie m 
    left join person d on m.DIRECTOR_ID = d.ID  -- pour aller chercher le film => TODO: pas d'index
where 
    d.name = 'Clint Eastwood'  
order by m.year
;

create index idx_movie_director on movie(director_id); -- index sur la clé étrangere => requete precedente OK : index person puis index director

-- gestion des PKS
-- * generation côté base auto
-- Oracle 12+ : clause identity => genere auto sequence + nextval
-- Oracle 9 à 11 : create sequence + trigger


create table note (
    id integer constraint pk_note primary key,
    note integer not null
);

create sequence seq_note_pk;

create trigger trg_note_pk
before insert on note
for each row
begin
    :new.id := seq_note_pk.nextval;
end;
/

insert into note (note) values (12);
select * from note;

insert into note (note) values (23);
insert into note (note) values (10);
insert into note (note) values (9);

select * from note;

-- last value of the sequence in this session
select seq_note_pk.currval from dual;
commit;

-- * generation auto pilotée par l'application avec numero fourni par la base : sequence seule
-- * generation auto generee par l'application : UUID 
