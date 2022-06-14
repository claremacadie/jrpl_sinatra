-- Postgres doesn't seem to like these, run them seperately if you need
--DROP DATABASE IF EXISTS jrpl_dev;
--CREATE DATABASE jrpl_dev;

DROP TABLE IF EXISTS points CASCADE;
DROP TABLE IF EXISTS scoring_system CASCADE;
DROP TABLE IF EXISTS prediction CASCADE;
DROP TABLE IF EXISTS emails CASCADE;
DROP TABLE IF EXISTS match CASCADE;
DROP TABLE IF EXISTS tournament_role CASCADE;
DROP TABLE IF EXISTS team CASCADE;
DROP TABLE IF EXISTS meta_group_map CASCADE;
DROP TABLE IF EXISTS meta_group CASCADE;
DROP TABLE IF EXISTS base_group CASCADE;
DROP TABLE IF EXISTS stage CASCADE;
DROP TABLE IF EXISTS venue CASCADE;
DROP TABLE IF EXISTS broadcaster CASCADE;
DROP TABLE IF EXISTS user_role CASCADE;
DROP TABLE IF EXISTS role CASCADE;
DROP TABLE IF EXISTS remember_me CASCADE;
DROP TABLE IF EXISTS users CASCADE;


CREATE TABLE users (
  user_id      integer      PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_name    varchar(50)  NOT NULL UNIQUE CHECK(user_name != ''),
  email        varchar(50)  NOT NULL UNIQUE CHECK(email != ''),
  pword        varchar(100) NOT NULL check(pword != '')
);

CREATE TABLE remember_me (
  user_id    int         NOT NULL REFERENCES users ON DELETE CASCADE ON UPDATE CASCADE,
  series_id  varchar(64) NOT NULL UNIQUE,
  token      varchar(64) NOT NULL,
  date_added timestamp   NOT NULL
);

CREATE TABLE role (
  role_id int      PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name varchar(50) NOT NULL
);

CREATE TABLE user_role (
  user_id      int NOT NULL REFERENCES users ON DELETE CASCADE ON UPDATE CASCADE,
  role_id      int NOT NULL REFERENCES role ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (user_id, role_id)
);

CREATE TABLE broadcaster (
  broadcaster_id  int         PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name            varchar(10) NOT NULL
);

CREATE TABLE venue (
  venue_id int         PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name     varchar(50) NOT NULL,
  city     varchar(50) NOT NULL,
  capacity int         NOT NULL
);

CREATE TABLE stage (
  stage_id int         PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name     varchar(50) NOT NULL
);

CREATE TABLE base_group (
  group_id        int         PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name            varchar(10) NOT NULL
);

CREATE TABLE meta_group (
  meta_group_id int         PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name          varchar(10) NOT NULL
);

CREATE TABLE meta_group_map (
  meta_group_id int NOT NULL REFERENCES meta_group ON DELETE CASCADE ON UPDATE CASCADE,
  group_id      int NOT NULL REFERENCES base_group ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (meta_group_id, group_id)
);

CREATE TABLE team (
  team_id    int         PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name       varchar(50) NOT NULL,
  short_name varchar(10) NOT NULL
);

CREATE TABLE tournament_role (
  tournament_role_id int         PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name               varchar(50) NOT NULL,
  team_id            int         NULL     REFERENCES team       ON DELETE CASCADE ON UPDATE CASCADE,
  from_match_id      int         NULL, -- references match, but can't put it in because match isn't yet created, so FK added at end
  from_group_id      int         NULL     REFERENCES meta_group ON DELETE CASCADE ON UPDATE CASCADE,
  stage_id           int         NOT NULL REFERENCES stage      ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE match (
  match_id         int       PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  date             date      NOT NULL,
  kick_off         time      NOT NULL,
  venue_id         int       NOT NULL REFERENCES venue           ON DELETE SET NULL,
  home_team_id     int       NOT NULL REFERENCES tournament_role ON DELETE CASCADE ON UPDATE CASCADE,
  away_team_id     int       NOT NULL REFERENCES tournament_role ON DELETE CASCADE ON UPDATE CASCADE,
  home_team_points int       NULL,
  away_team_points int       NULL,
  result_posted_by int       NULL     REFERENCES users           ON DELETE SET NULL,
  result_posted_on timestamp NULL,
  stage_id         int       NOT NULL REFERENCES stage           ON DELETE CASCADE ON UPDATE CASCADE,
  broadcaster_id   int       NOT NULL REFERENCES broadcaster     ON DELETE SET NULL
);

CREATE TABLE emails (
  match_id         int     NOT NULL REFERENCES match ON DELETE CASCADE ON UPDATE CASCADE,
  predictions_sent boolean NOT NULL,
  results_sent     boolean NOT NULL,
  PRIMARY KEY (match_id)
);

CREATE TABLE prediction (
  prediction_id    int       PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id          int       NOT NULL REFERENCES users ON DELETE CASCADE ON UPDATE CASCADE,
  match_id         int       NOT NULL REFERENCES match ON DELETE CASCADE ON UPDATE CASCADE,
  home_team_points int       NOT NULL,
  away_team_points int       NOT NULL,
  date_added       timestamp NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, match_id)
);

CREATE TABLE scoring_system (
  scoring_system_id int         PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name              varchar(50) NOT NULL
);

CREATE TABLE points (
  prediction_id     int          NOT NULL REFERENCES prediction     ON DELETE CASCADE ON UPDATE CASCADE,
  scoring_system_id int          NOT NULL REFERENCES scoring_system ON DELETE CASCADE ON UPDATE CASCADE,
  result_points     numeric(6,2) NOT NULL,
  score_points      numeric(6,2) NOT NULL,
  total_points      numeric(6,2) NOT NULL,
  PRIMARY KEY (prediction_id, scoring_system_id)
);

ALTER TABLE tournament_role
ADD FOREIGN KEY (from_match_id) 
REFERENCES match(match_id) ON DELETE CASCADE ON UPDATE CASCADE;
