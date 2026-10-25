-- play as user proprietary

truncate table play;
truncate table have_genre;
truncate table movie;
truncate table person;

@02-data-person.sql
@03-data-movie.sql
@04-data-play.sql
@05-data-genre.sql
@99-checkup
