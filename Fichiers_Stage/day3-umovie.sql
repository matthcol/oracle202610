-- user umovie, base métier

-- blocs pour provoquer beaucoup de rotation de logs et d'archivages
declare
    v_base_title movie.title%type;
begin
    v_base_title := 'Fast and Furious ';
    for i in 1..10000 loop
        insert into movie (title, year)
            values (v_base_title || i, 2026);
        commit;
    end loop;
end;
/
select count(*) from movie; -- 11 188

declare
    v_base_title movie.title%type;
begin
    v_base_title := 'Rambo ';
    for i in 1..100000 loop
        insert into movie (title, year)
            values (v_base_title || i, 2026);
        commit;
    end loop;
end;
/

select count(*) from movie; -- 11 188




declare
    v_base_title movie.title%type;
begin
    v_base_title := 'Jaws ';
    for i in 1..1000000 loop
        insert into movie (title, year)
            values (v_base_title || i, 2026);
        commit;
    end loop;
end;
/

declare
    v_base_title varchar;
begin
    v_base_title := 'Gremlins ';
    for i in 1..10000000 loop
        insert into movie (title, year)
            values (v_base_title || i, 2026);
        commit;
    end loop;
end;
/

-- apres un dump et des backup
delete play where mod(actor_id,  2 ) = 0;
commit;

-- incident logiciel
select count(*) from play; -- 32949

-- reparation : import avec remap et reinserezr les lignes manquantes
-- drop table play_remap;
select count(*) from play_remap; -- 66520
select count(*)   -- 33571
from play_remap plr
where not exists (
    select 1 from play pl
    where 
        pl.actor_id = plr.actor_id
        and pl.movie_id = plr.movie_id
);

insert into PLAY
    select *
    from play_remap plr
    where not exists (
        select 1 from play pl
        where 
            pl.actor_id = plr.actor_id
            and pl.movie_id = plr.movie_id
    );
-- 33 571 Rows inserted
commit;
select count(*) from play; -- 66520



-- requetes couteuses

with director_selection as (
    select *
    from person
    where name in (
        'Clint Eastwood',
        'Steven Spielberg',
        'Quentin Tarantino',
        'Martin Scorsese',
        'Danny Boyle'
    )
)
select *
from person person_actor
where not exists (
    select * from director_selection person_director
    where not exists (
        select *
        from 
            play pl
            join movie m on pl.movie_id = m.id
        where
            person_actor.id = pl.actor_id
            and person_director.id = m.director_id
    )
);

with director_selection as (
    select *
    from person
    where name in (
        'Clint Eastwood',
        'Steven Spielberg',
        'Quentin Tarantino',
        'Martin Scorsese',
        'Danny Boyle'
    )
)
select *
from person person_actor
where not exists (
    select 1 from director_selection person_director
    where not exists (
        select 1
        from 
            play pl
            join movie m on pl.movie_id = m.id
        where
            person_actor.id = pl.actor_id
            and person_director.id = m.director_id
    )
);



