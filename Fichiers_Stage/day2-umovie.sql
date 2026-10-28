-- user umovie
-- base metier

-- fonction retournant "<title> (<year>)", titre tronque a 20 caracteres si trop long
create or replace function title_year(
    p_title in movie.title%type,
    p_year  in movie.year%type
) return varchar2
is
begin
    return case
        when length(p_title) > 20 then substr(p_title, 1, 20)
        else p_title
    end || ' (' || p_year || ')';
end title_year;
/

select title_year(title, year) from movie where year = 1984;

-- procedure illustrant %ROWTYPE : recupere un film et son realisateur
-- dans des variables typees sur les tables movie et person
create or replace procedure show_movie_director(
    p_movie_id in movie.id%type
)
is
    v_movie  movie%rowtype;
    v_person person%rowtype;
begin
    select * into v_movie from movie where id = p_movie_id;

    select * into v_person from person where id = v_movie.director_id;

    dbms_output.put_line(title_year(v_movie.title, v_movie.year) || ' realise par ' || v_person.name);
exception
    when no_data_found then
        dbms_output.put_line('film ou realisateur introuvable pour id = ' || p_movie_id);
end show_movie_director;
/

select * from movie where title like '%Terminator%';
exec show_movie_director(88247);


select user from dual; --umovie

-- synonymes publiques
select * from user_tables;  -- owner = umovie
select * from sys.user_tables;
-- autres synonymes publiques
select * from all_tables where owner = 'UMOVIE';
select * from USER_VIEWS;
select * from USER_INDEXES;
select * from USER_SEQUENCES;
select * from USER_TRIGGERS;
select * from USER_PROCEDURES; -- function + PROCEDURE + TRIGGER
select * from USER_;
select * from USER_OBJECTS order by OBJECT_TYPE;

select count(*) from movie; -- raccourci sur ses objets
select count(*) from umovie.movie;

select * from DBA_ALL_TABLES;

create view v_movie1980s as (
    select title, year, duration, director_id
    from MOVIE       
    where YEAR BETWEEN 1980 AND 1989
);

create view v_movie1990s as (
    select title, year, duration, director_id
    from MOVIE       
    where YEAR BETWEEN 1990 AND 1999
);

create view v_movie2000s as (
    select title, year, duration, director_id
    from MOVIE       
    where YEAR BETWEEN 2000 AND 2010
);

create view v_movie2010s as (
    select title, year, duration, director_id
    from MOVIE       
    where YEAR BETWEEN 2010 AND 2020
);

create view v_movie2020s as (
    select title, year, duration, director_id
    from MOVIE       
    where YEAR BETWEEN 2020 AND 2030
);

drop view v_movie_latest;
create view v_movie_latest as (
    select id, title, year, duration, director_id
    from MOVIE       
    where YEAR > extract(year from current_date) - 10
);
select * from v_movie_latest order by year desc;

create public synonym person for umovie.person;

select * from person;

-- *************************
--     atelier roles
-- *************************
create role r_reader;
create role r_contrib;
grant r_reader to r_contrib;

-- emboitement des roles : r_reader est "dans" r_contrib
-- visible ici sans grant a soi-meme car umovie est proprietaire des 2 roles (il les a crees)
select * from role_role_privs where role = 'R_CONTRIB';

-- TODO : recuperer le SQL stagiaire


-- securiser la vue v_movie_latest pour faire des MAJ
drop view v_movie_latest;
create view v_movie_latest as (
    select id, title, year, duration, director_id
    from MOVIE       
    where YEAR > extract(year from current_date) - 10
) with check option;