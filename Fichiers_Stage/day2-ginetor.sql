-- user ginetor : user tiers utilise les données du schema movie
select * from umovie.person;
select * from umovie.movie;
select * from umovie.v_movie_latest;

insert into umovie.v_movie_latest (title, year) values ('Spider-Man: Brand New Day', 2026);
commit;

select * from umovie.v_movie_latest order by year desc;