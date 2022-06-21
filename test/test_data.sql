TRUNCATE points RESTART IDENTITY CASCADE;
TRUNCATE scoring_system RESTART IDENTITY CASCADE;
TRUNCATE prediction RESTART IDENTITY CASCADE;
TRUNCATE emails RESTART IDENTITY CASCADE;
TRUNCATE match RESTART IDENTITY CASCADE;
TRUNCATE tournament_role RESTART IDENTITY CASCADE;
TRUNCATE team RESTART IDENTITY CASCADE;
TRUNCATE meta_group_map RESTART IDENTITY CASCADE;
TRUNCATE meta_group RESTART IDENTITY CASCADE;
TRUNCATE base_group RESTART IDENTITY CASCADE;
TRUNCATE stage RESTART IDENTITY CASCADE;
TRUNCATE venue RESTART IDENTITY CASCADE;
TRUNCATE broadcaster RESTART IDENTITY CASCADE;
TRUNCATE user_role RESTART IDENTITY CASCADE;
TRUNCATE role RESTART IDENTITY CASCADE;
TRUNCATE remember_me RESTART IDENTITY CASCADE;
TRUNCATE users RESTART IDENTITY CASCADE;

INSERT INTO users
    (user_name,    email,                                  pword) VALUES
    ('Mr. Mean',   'mrmean@julianrimet.com',               '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Mr. Median', 'mrmedian@julianrimet.com',             '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Mr. Mode',   'mrmode@julianrimet.com',               '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Maccas',     'james.macadie@telerealtrillium.com',   '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Binary Boy', 'richard.morrison3@googlemail.com',     '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('DTM',        'dan.smith@citi.com',                   '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Will Mac',   'will.macadie@gmail.com',               '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Kov',        'doctorkov@googlemail.com',             '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Sammie',     'sarahkowenicki@hotmail.com',           '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Uwe',        'markrusling@hotmail.com',              '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Clare Mac',  'clare@macadie.co.uk',                  '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Tom Mac',    'tom_macadie@hotmail.com',              '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Fi Mac',     'fknox1@hotmail.com',                   '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Matt',       'mattmargrett@gmail.com',               '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('G.Mozz',     'gmorrison100@gmail.com',               '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Haller',     'james.russell.hall@gmail.com',         '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Archie',     'archie.bland@theguardian.com',         '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Ben',        'ben@benhart.co.uk',                    '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Ollie',      'oliver.peck@rocketmail.com',           '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('David',      'david@davidhart.co.uk',                '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Coups',      'pcoupar@hotmail.com',                  '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Peck',       'tompeck1000@gmail.com',                '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Gen',        'gen.smith@gmail.com',                  '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Diego',      'martin.ayers@talk21.com',              '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Ross',       'rceallen@gmail.com',                   '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Mark S',     'maspinks@hotmail.com',                 '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Mond',       'desmcewan@hotmail.com',                '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Lottie',     'happylottie@hotmail.com',              '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Sven',       'jari.stehn@gmail.com',                 '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Lady Peck',  'alice.jones@inews.co.uk',              '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('galsnakes',  'Sam.Gallagher@progressivecontent.com', '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Jonny',      'jonnyzpearson@gmail.com',              '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Manon',      'manoncornu@live.fr',                   '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
    ('Rosa',       'rosama68@hotmail.com',                 '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6');

INSERT INTO role (name) VALUES
    ('Admin'),
    ('Mr Mean'),
    ('Mr Median'),
    ('Mr Mode');
    
INSERT INTO user_role (user_id, role_id) VALUES
    (1, 2),
    (2, 3),
    (3, 4),
    (4, 1);

INSERT INTO broadcaster (name) VALUES
    ('BBC'),
    ('ITV'),
    ('ITV 4'),
    ('TBD');

INSERT INTO venue
    (name,                            city,           capacity) VALUES
    ('Al Thumama Stadium',            'Doha',         40000),
    ('Khalifa International Stadium', 'Doha',         45416),
    ('Al Bayt Stadium',               'Al Khor City', 60000),
    ('Ahmad Bin Ali Stadium',         'Al Rayyan',    40000),
    ('Lusail Stadium',                'Doha',         80000),
    ('Education City Stadium',        'Al Rayyan',    40000),
    ('Stadium 974',                   'Doha',         40000),
    ('Al Janoub Stadium',             'Al Wakrah',    40000);

INSERT INTO stage (name) VALUES
    ('Group Stages'),
    ('Round of 16'),
    ('Quarter Finals'),
    ('Semi Finals'),
    ('Third Fourth Place Play-off'),
    ('Final');

INSERT INTO base_group (name) VALUES
    ('A'),
    ('B'),
    ('C'),
    ('D'),
    ('E'),
    ('F'),
    ('G'),
    ('H');

INSERT INTO meta_group (name) VALUES
    ('A'),
    ('B'),
    ('C'),
    ('D'),
    ('E'),
    ('F'),
    ('G'),
    ('H');

INSERT INTO meta_group_map (meta_group_id, group_id) VALUES
    (1, 1),
    (2, 2),
    (3, 3),
    (4, 4),
    (5, 5),
    (6, 6),
    (7, 7),
    (8, 8);

INSERT INTO team (name, short_name) VALUES
    ('Qatar', 'QAT'),
    ('Ecuador', 'ECU'),
    ('Senegal', 'SEN'),
    ('Netherlands', 'NLD'),
    ('England', 'ENG'),
    ('Iran', 'IRN'),
    ('USA', 'USA'),
    ('Euro PlayOff', 'EUR'),
    ('Argentina', 'ARG'),
    ('Saudi Arabia', 'SAU'),
    ('Mexico', 'MEX'),
    ('Poland', 'POL'),
    ('France', 'FRA'),
    ('IC Play Off 1', 'IC1'),
    ('Denmark', 'DNK'),
    ('Tunisia', 'TUN'),
    ('Spain', 'ESP'),
    ('IC Play Off 2', 'IC2'),
    ('Germany', 'DEU'),
    ('Japan', 'JPN'),
    ('Belgium', 'BEL'),
    ('Canada', 'CAN'),
    ('Morocco', 'MAR'),
    ('Croatia', 'HRV'),
    ('Brazil', 'BRA'),
    ('Serbia', 'SRB'),
    ('Switzerland', 'CHE'),
    ('Cameroon', 'CMR'),
    ('Portugal', 'PRT'),
    ('Ghana', 'GHA'),
    ('Uruguay', 'URY'),
    ('Korea Republic', 'KOR');

INSERT INTO tournament_role
    (name,                     team_id, from_match_id, from_group_id, stage_id) VALUES
    ('Group A Team 1',         1,       NULL,          1,             1),
    ('Group A Team 2',         2,       NULL,          1,             1),
    ('Group A Team 3',         3,       NULL,          1,             1),
    ('Group A Team 4',         4,       NULL,          1,             1),
    ('Group B Team 1',         5,       NULL,          2,             1),
    ('Group B Team 2',         6,       NULL,          2,             1),
    ('Group B Team 3',         7,       NULL,          2,             1),
    ('Group B Team 4',         8,       NULL,          2,             1),
    ('Group C Team 1',         9,       NULL,          3,             1),
    ('Group C Team 2',         10,      NULL,          3,             1),
    ('Group C Team 3',         11,      NULL,          3,             1),
    ('Group C Team 4',         12,      NULL,          3,             1),
    ('Group D Team 1',         13,      NULL,          4,             1),
    ('Group D Team 2',         14,      NULL,          4,             1),
    ('Group D Team 3',         15,      NULL,          4,             1),
    ('Group D Team 4',         16,      NULL,          4,             1),
    ('Group E Team 1',         17,      NULL,          5,             1),
    ('Group E Team 2',         18,      NULL,          5,             1),
    ('Group E Team 3',         19,      NULL,          5,             1),
    ('Group E Team 4',         20,      NULL,          5,             1),
    ('Group F Team 1',         21,      NULL,          6,             1),
    ('Group F Team 2',         22,      NULL,          6,             1),
    ('Group F Team 3',         23,      NULL,          6,             1),
    ('Group F Team 4',         24,      NULL,          6,             1),
    ('Group G Team 1',         25,      NULL,          7,             1),
    ('Group G Team 2',         26,      NULL,          7,             1),
    ('Group G Team 3',         27,      NULL,          7,             1),
    ('Group G Team 4',         28,      NULL,          7,             1),
    ('Group H Team 1',         29,      NULL,          8,             1),
    ('Group H Team 2',         30,      NULL,          8,             1),
    ('Group H Team 3',         31,      NULL,          8,             1),
    ('Group H Team 4',         32,      NULL,          8,             1),
    ('Winner Group A',         NULL,    NULL,          1,             2),
    ('Runner Up Group A',      NULL,    NULL,          1,             2),
    ('Winner Group B',         NULL,    NULL,          2,             2),
    ('Runner Up Group B',      NULL,    NULL,          2,             2),
    ('Winner Group C',         NULL,    NULL,          3,             2),
    ('Runner Up Group C',      NULL,    NULL,          3,             2),
    ('Winner Group D',         NULL,    NULL,          4,             2),
    ('Runner Up Group D',      NULL,    NULL,          4,             2),
    ('Winner Group E',         NULL,    NULL,          5,             2),
    ('Runner Up Group E',      NULL,    NULL,          5,             2),
    ('Winner Group F',         NULL,    NULL,          6,             2),
    ('Runner Up Group F',      NULL,    NULL,          6,             2),
    ('Winner Group G',         NULL,    NULL,          7,             2),
    ('Runner Up Group G',      NULL,    NULL,          7,             2),
    ('Winner Group H',         NULL,    NULL,          8,             2),
    ('Runner Up Group H',      NULL,    NULL,          8,             2),
    ('Winner R16 1',           NULL,    NULL,           NULL,           3),
    ('Winner R16 2',           NULL,    NULL,           NULL,           3),
    ('Winner R16 3',           NULL,    NULL,           NULL,           3),
    ('Winner R16 4',           NULL,    NULL,           NULL,           3),
    ('Winner R16 5',           NULL,    NULL,           NULL,           3),
    ('Winner R16 6',           NULL,    NULL,           NULL,           3),
    ('Winner R16 7',           NULL,    NULL,           NULL,           3),
    ('Winner R16 8',           NULL,    NULL,           NULL,           3),
    ('Winner Quarter-Final 1', NULL,    NULL,           NULL,           4),
    ('Winner Quarter-Final 2', NULL,    NULL,           NULL,           4),
    ('Winner Quarter-Final 3', NULL,    NULL,           NULL,           4),
    ('Winner Quarter-Final 4', NULL,    NULL,           NULL,           4),
    ('Loser Semi-Final 1',     NULL,    NULL,           NULL,           5),
    ('Loser Semi-Final 2',     NULL,    NULL,           NULL,           5),
    ('Winner Semi-Final 1',    NULL,    NULL,           NULL,           6),
    ('Winner Semi-Final 2',    NULL,    NULL,           NULL,           6);

INSERT INTO match
    (date,         kick_off,   venue_id, home_team_id, away_team_id, home_team_points, away_team_points, result_posted_by, result_posted_on, stage_id, broadcaster_id) VALUES
    ('2021-11-21', '20:00:00', 1,        3,            4,               6,                3,             NULL,             NULL,             1,        1),
    ('2021-11-21', '16:00:00', 2,        5,            6,               4,                5,             NULL,             NULL,             1,        1),
    ('2021-11-21', '19:00:00', 3,        1,            2,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2021-11-21', '22:00:00', 4,        7,            8,            NULL,             NULL,             NULL,             NULL,             1,        1),
    (CURRENT_DATE, split_part((CURRENT_TIME + interval '15 minute')::text, '.', 1)::time, 5,        9,           10,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2021-11-22', '16:00:00', 6,       15,           16,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2021-11-22', '19:00:00', 7,       11,           12,              61,               62,             NULL,             NULL,             1,        1),
    ('2021-11-22', '22:00:00', 8,       13,           14,              63,               64,             NULL,             NULL,             1,        1),
    ('2022-11-23', '13:00:00', 3,       23,           24,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-23', '16:00:00', 2,       19,           20,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-23', '19:00:00', 1,       17,           18,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-23', '22:00:00', 4,       21,           22,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-24', '13:00:00', 8,       27,           28,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-24', '16:00:00', 6,       31,           32,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-24', '19:00:00', 7,       29,           30,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-24', '22:00:00', 5,       25,           26,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-25', '13:00:00', 4,        8,            6,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-25', '16:00:00', 1,        1,            3,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-25', '19:00:00', 2,        4,            2,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-25', '22:00:00', 3,        5,            7,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-26', '13:00:00', 8,       16,           14,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-26', '16:00:00', 6,       12,           10,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-26', '19:00:00', 7,       13,           15,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-26', '22:00:00', 5,        9,           11,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-27', '13:00:00', 4,       20,           18,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-27', '16:00:00', 1,       21,           23,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-27', '19:00:00', 2,       24,           22,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-27', '22:00:00', 3,       17,           19,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-28', '13:00:00', 8,       28,           26,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-28', '16:00:00', 6,       32,           30,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-28', '19:00:00', 7,       25,           27,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-28', '22:00:00', 5,       29,           31,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-29', '18:00:00', 2,        2,            3,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-29', '18:00:00', 3,        4,            1,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-29', '22:00:00', 4,        8,            5,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-29', '22:00:00', 1,        6,            7,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-30', '18:00:00', 8,       14,           15,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-30', '18:00:00', 6,       16,           13,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-30', '22:00:00', 7,       12,            9,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-30', '22:00:00', 5,       10,           11,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-12-01', '18:00:00', 4,       24,           21,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-12-01', '18:00:00', 1,       22,           23,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-12-01', '22:00:00', 2,       20,           17,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-12-01', '22:00:00', 3,       18,           19,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-12-02', '18:00:00', 8,       30,           31,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-12-02', '18:00:00', 6,       32,           29,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-12-02', '22:00:00', 7,       26,           27,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-12-02', '22:00:00', 5,       28,           25,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-12-03', '18:00:00', 2,       33,           36,            NULL,             NULL,             NULL,             NULL,             2,        1),
    ('2022-12-03', '22:00:00', 4,       37,           40,            NULL,             NULL,             NULL,             NULL,             2,        1),
    ('2022-12-04', '18:00:00', 1,       39,           38,            NULL,             NULL,             NULL,             NULL,             2,        1),
    ('2022-12-04', '22:00:00', 3,       35,           34,            NULL,             NULL,             NULL,             NULL,             2,        1),
    ('2022-12-05', '18:00:00', 8,       41,           44,            NULL,             NULL,             NULL,             NULL,             2,        1),
    ('2022-12-05', '22:00:00', 7,       45,           48,            NULL,             NULL,             NULL,             NULL,             2,        1),
    ('2022-12-06', '18:00:00', 6,       43,           42,            NULL,             NULL,             NULL,             NULL,             2,        1),
    ('2022-12-06', '22:00:00', 5,       47,           46,            NULL,             NULL,             NULL,             NULL,             2,        1),
    ('2022-12-09', '18:00:00', 6,       53,           54,            NULL,             NULL,             NULL,             NULL,             3,        1),
    ('2022-12-09', '22:00:00', 5,       49,           50,            NULL,             NULL,             NULL,             NULL,             3,        1),
    ('2022-12-10', '18:00:00', 1,       55,           56,            NULL,             NULL,             NULL,             NULL,             3,        1),
    ('2022-12-10', '22:00:00', 3,       52,           51,            NULL,             NULL,             NULL,             NULL,             3,        1),
    ('2022-12-13', '22:00:00', 5,       57,           58,            NULL,             NULL,             NULL,             NULL,             4,        1),
    ('2022-12-14', '22:00:00', 3,       59,           60,            NULL,             NULL,             NULL,             NULL,             4,        1),
    ('2022-12-17', '18:00:00', 2,       61,           62,            NULL,             NULL,             NULL,             NULL,             5,        1),
    ('2022-12-17', '18:00:00', 5,       63,           64,            NULL,             NULL,             NULL,             NULL,             6,        1);

INSERT INTO emails (match_id, predictions_sent, results_sent) VALUES
    (1, FALSE, FALSE),
    (2, FALSE, FALSE),
    (3, FALSE, FALSE),
    (4, FALSE, FALSE),
    (5, FALSE, FALSE),
    (6, FALSE, FALSE),
    (7, FALSE, FALSE),
    (8, FALSE, FALSE),
    (9, FALSE, FALSE),
    (10, FALSE, FALSE),
    (11, FALSE, FALSE),
    (12, FALSE, FALSE),
    (13, FALSE, FALSE),
    (14, FALSE, FALSE),
    (15, FALSE, FALSE),
    (16, FALSE, FALSE),
    (17, FALSE, FALSE),
    (18, FALSE, FALSE),
    (19, FALSE, FALSE),
    (20, FALSE, FALSE),
    (21, FALSE, FALSE),
    (22, FALSE, FALSE),
    (23, FALSE, FALSE),
    (24, FALSE, FALSE),
    (25, FALSE, FALSE),
    (26, FALSE, FALSE),
    (27, FALSE, FALSE),
    (28, FALSE, FALSE),
    (29, FALSE, FALSE),
    (30, FALSE, FALSE),
    (31, FALSE, FALSE),
    (32, FALSE, FALSE),
    (33, FALSE, FALSE),
    (34, FALSE, FALSE),
    (35, FALSE, FALSE),
    (36, FALSE, FALSE),
    (37, FALSE, FALSE),
    (38, FALSE, FALSE),
    (39, FALSE, FALSE),
    (40, FALSE, FALSE),
    (41, FALSE, FALSE),
    (42, FALSE, FALSE),
    (43, FALSE, FALSE),
    (44, FALSE, FALSE),
    (45, FALSE, FALSE),
    (46, FALSE, FALSE),
    (47, FALSE, FALSE),
    (48, FALSE, FALSE),
    (49, FALSE, FALSE),
    (50, FALSE, FALSE),
    (51, FALSE, FALSE),
    (52, FALSE, FALSE),
    (53, FALSE, FALSE),
    (54, FALSE, FALSE),
    (55, FALSE, FALSE),
    (56, FALSE, FALSE),
    (57, FALSE, FALSE),
    (58, FALSE, FALSE),
    (59, FALSE, FALSE),
    (60, FALSE, FALSE),
    (61, FALSE, FALSE),
    (62, FALSE, FALSE),
    (63, FALSE, FALSE),
    (64, FALSE, FALSE);

UPDATE tournament_role
    SET from_match_id = 49 WHERE name = 'Winner R16 1';
UPDATE tournament_role
    SET from_match_id = 50 WHERE name = 'Winner R16 2';
UPDATE tournament_role
    SET from_match_id = 51 WHERE name = 'Winner R16 3';
UPDATE tournament_role
    SET from_match_id = 52 WHERE name = 'Winner R16 4';
UPDATE tournament_role
    SET from_match_id = 53 WHERE name = 'Winner R16 5';
UPDATE tournament_role
    SET from_match_id = 54 WHERE name = 'Winner R16 6';
UPDATE tournament_role
    SET from_match_id = 55 WHERE name = 'Winner R16 7';
UPDATE tournament_role
    SET from_match_id = 56 WHERE name = 'Winner R16 8';
UPDATE tournament_role
    SET from_match_id = 57 WHERE name = 'Winner Quarter-Final 1';
UPDATE tournament_role
    SET from_match_id = 58 WHERE name = 'Winner Quarter-Final 2';
UPDATE tournament_role
    SET from_match_id = 59 WHERE name = 'Winner Quarter-Final 3';
UPDATE tournament_role
    SET from_match_id = 60 WHERE name = 'Winner Quarter-Final 4';
UPDATE tournament_role
    SET from_match_id = 61 WHERE name = 'Loser Semi-Final 1';
UPDATE tournament_role
    SET from_match_id = 62 WHERE name = 'Loser Semi-Final 2';
UPDATE tournament_role
    SET from_match_id = 61 WHERE name = 'Winner Semi-Final 1';
UPDATE tournament_role
    SET from_match_id = 62 WHERE name = 'Winner Semi-Final 2';

INSERT INTO scoring_system (name) VALUES
    ('official'),
    ('autoquiz');

INSERT INTO prediction (user_id, match_id, home_team_points, away_team_points, date_added) VALUES
    (11, 11, 77, 78, '2022-06-12 16:45:15'),
    (4, 12, 88, 89, '2022-06-13 11:45:15'),
    (11, 6, 71, 72, '2022-06-12 16:45:15'),
    (4, 6, 81, 82, '2022-06-13 11:45:15'),
    (11, 8, 73, 74, '2022-06-12 16:45:15'),
    (4, 8, 83, 84, '2022-06-13 11:45:15'),
    (11, 7, 6, 6, '2022-06-12 16:45:15'),
    (4, 7, 4, 2, '2022-06-13 11:45:15'),
    (1, 11, 1, 0, '2022-06-12 16:45:15'),
    (2, 12, 0, 1, '2022-06-13 11:45:15'),
    (1, 6, 0, 0, '2022-06-12 16:45:15'),
    (2, 6, 2, 1, '2022-06-13 11:45:15'),
    (1, 8, 1, 73, '2022-06-12 16:45:15'),
    (2, 8, 2, 2, '2022-06-13 11:45:15'),
    (1, 7, 2, 1, '2022-06-12 16:45:15'),
    (2, 7, 1, 2, '2022-06-13 11:45:15');

INSERT INTO points (prediction_id, scoring_system_id, result_points, score_points, total_points) VALUES 
    (7, 1, 1, 2, 3),
    (8, 1, 1, 0, 1),
    (7, 2, 2, 4, 6),
    (8, 2, 2, 0, 2);
