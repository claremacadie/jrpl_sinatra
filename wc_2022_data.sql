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
    (first_name,  last_name,   display_name, email,                                  pword) VALUES
    ('Mr.',       'Mean',      'Mr. Mean',   'mrmean@julianrimet.com',               'f0c9a442ef67e81b3a1340ae95700eb3'),
    ('Mr.',       'Median',    'Mr. Median', 'mrmedian@julianrimet.com',             'f0c9a442ef67e81b3a1340ae95700eb3'),
    ('Mr.',       'Mode',      'Mr. Mode',   'mrmode@julianrimet.com',               'f0c9a442ef67e81b3a1340ae95700eb3'),
    ('James',     'MacAdie',   'Maccas',     'james.macadie@telerealtrillium.com',   'e30a23724ec797c00135c9a6eccda61c'),
    ('Richard',   'Morrison',  'Binary Boy', 'richard.morrison3@googlemail.com',     '4039d3083f93bb8623b58b626b50d7b0'),
    ('Dan',       'Smith',     'DTM',        'dan.smith@citi.com',                   '9cf2146a2ebedb2e23af62c4e0d41f98'),
    ('William',   'MacAdie',   'Will Mac',   'will.macadie@gmail.com',               '74c46d2453cc27f2911432363c986746'),
    ('Richard',   'Kowenicki', 'Kov',        'doctorkov@googlemail.com',             '4011bbf0faf06684cc7eba99d2d016dd'),
    ('Sarah',     'Kowenicki', 'Sammie',     'sarahkowenicki@hotmail.com',           'eeaae7a93367d447ef056708acbc6116'),
    ('Mark',      'Rusling',   'Uwe',        'markrusling@hotmail.com',              '6d73f43911551b5ed98b7d6d712bf591'),
    ('Clare',     'MacAdie',   'Clare Mac',  'clare@macadie.co.uk',                  'e706adb60ed514bd612e49c915425ed1'),
    ('Tom',       'MacAdie',   'Tom Mac',    'tom_macadie@hotmail.com',              '45a79221ef9f6bc2dfb4e21ad6c6f9d9'),
    ('Fiona',     'MacAdie',   'Fi Mac',     'fknox1@hotmail.com',                   '713dc3d995d57eb25e632786983ee2f3'),
    ('Matt',      'Margrett',  'Matt',       'mattmargrett@gmail.com',               '2d0fb7f2e960f8c47ce514ce8a863c69'),
    ('Graham',    'Morrison',  'G.Mozz',     'gmorrison100@gmail.com',               'baaf4a1cc7c187378e67535a2fb148a6'),
    ('James',     'Hall',      'Haller',     'james.russell.hall@gmail.com',         '6e20c6b09ad5c38d6da40696f6713c8f'),
    ('Archie',    'Bland',     'Archie',     'archie.bland@theguardian.com',         'f0c9a442ef67e81b3a1340ae95700eb3'),
    ('Benjamin ', 'Hart',      'Ben',        'ben@benhart.co.uk',                    '2566ce3b7e59f9f23baeb77e7d4fe044'),
    ('Oliver',    'Peck',      'Ollie',      'oliver.peck@rocketmail.com',           'f8b4ad619a9b4f9f50451943b0b268ba'),
    ('David',     'Hart',      'David',      'david@davidhart.co.uk',                '52ce8dcc2d13295f76dcba6025b0f8ef'),
    ('Paul',      'Coupar',    'Coups',      'pcoupar@hotmail.com',                  '96ed9a860e90485c20c1030095b3b16c'),
    ('Tom',       'Peck',      'Peck',       'tompeck1000@gmail.com',                '9d37874755d2f8f9cd2779996048f97f'),
    ('Genevieve', 'Smith',     'Gen',        'gen.smith@gmail.com',                  'c4683de7ded706807b711abf5b37f79b'),
    ('Martin',    'Ayers',     'Diego',      'martin.ayers@talk21.com',              'f0c9a442ef67e81b3a1340ae95700eb3'),
    ('Ross',      'Allen',     'Ross',       'rceallen@gmail.com',                   '410e30c15c7c9f7b5dde86ee9227c458'),
    ('Mark',      'Spinks',    'Mark S',     'maspinks@hotmail.com',                 '00a51fd1eea9f936d90f4809e62bc423'),
    ('Des',       'McEwan',    'Mond',       'desmcewan@hotmail.com',                'dcfab7445dd7fb9779750c56ce581e54'),
    ('Charlotte', 'Peck',      'Lottie',     'happylottie@hotmail.com',              'efbed475f64469145e9b8d19f838b588'),
    ('Jari',      'Stehn',     'Sven',       'jari.stehn@gmail.com',                 'f0c9a442ef67e81b3a1340ae95700eb3'),
    ('Alice',     'Jones',     'Lady Peck',  'alice.jones@inews.co.uk',              '78c8566f78eb142414d15bd1e73bcffe'),
    ('Sam',       'Gallagher', 'galsnakes',  'Sam.Gallagher@progressivecontent.com', '876a9703f04b99cc019c7bc6df3c02b4'),
    ('Jonny',     'Pearson',   'Jonny',      'jonnyzpearson@gmail.com',              '87a7c24bf14d213c9f9ddbcb2c04dddc'),
    ('Manon',     'Cornu',     'Manon',      'manoncornu@live.fr',                   'f0c9a442ef67e81b3a1340ae95700eb3'),
    ('Rosa',      'Monserrat', 'Rosa',       'rosama68@hotmail.com',                 'f0c9a442ef67e81b3a1340ae95700eb3');

INSERT INTO role (name) VALUES
    ('Admin'),
    ('Mr Mean'),
    ('Mr Median'),
    ('Mr Mode');

INSERT INTO user_role (user_id, role_id) VALUES
    (4, 1),
    (1, 2),
    (2, 3),
    (3, 4);

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
    ('2022-11-21', '13:00:00', 1,        3,            4,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-21', '16:00:00', 2,        5,            6,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-21', '19:00:00', 3,        1,            2,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-21', '22:00:00', 4,        7,            8,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-22', '13:00:00', 5,        9,           10,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-22', '16:00:00', 6,       15,           16,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-22', '19:00:00', 7,       11,           12,            NULL,             NULL,             NULL,             NULL,             1,        1),
    ('2022-11-22', '22:00:00', 8,       13,           14,            NULL,             NULL,             NULL,             NULL,             1,        1),
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
    ('Official'),
    ('AutoQuiz');
