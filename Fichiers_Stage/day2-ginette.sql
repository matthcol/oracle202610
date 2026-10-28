-- user ginette : user tiers utilise les données du schema movie

-- ginette a le role r_reader
select * from umovie.person;
select * from umovie.movie;
select * from umovie.v_movie_latest;

-- avec les synonymes
select * from person;
select * from movie;
select * from v_movie_latest;

-- SQL Error: ORA-01031: insufficient privileges
insert into umovie.v_movie_latest (title, year) values ('Dune: Part 3', 2026);