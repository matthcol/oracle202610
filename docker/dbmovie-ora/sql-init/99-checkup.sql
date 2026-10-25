CONN umovie/password@localhost/dbmovie

select 'movie' as table_name, count(*) as row_count from movie
union
select 'person' as table_name, count(*) as row_count from person
union
select 'play' as table_name, count(*) as row_count from play
union
select 'have_genre' as table_name, count(*) as row_count from have_genre
;