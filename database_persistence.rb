require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = if ENV['RACK_ENV'] == 'test'
            PG.connect(dbname: 'jrpl_test')
          else
            PG.connect(dbname: 'jrpl')
          end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def upload_new_user_credentials(user_details)
    hashed_pword = BCrypt::Password.create(user_details[:pword]).to_s
    sql = 'INSERT INTO users (user_name, email, pword) VALUES ($1, $2, $3)'
    query(sql, user_details[:user_name], user_details[:email], hashed_pword)
  end

  def change_username(old_user_name, new_user_name)
    sql = 'UPDATE users SET user_name = $1 WHERE user_name = $2'
    query(sql, new_user_name, old_user_name)
  end

  def change_pword(old_user_name, new_pword)
    hashed_pword = BCrypt::Password.create(new_pword).to_s
    sql = 'UPDATE users SET pword = $1 WHERE user_name = $2'
    query(sql, hashed_pword, old_user_name)
  end

  def change_email(old_user_name, new_email)
    sql = 'UPDATE users SET email = $1 WHERE user_name = $2'
    query(sql, new_email, old_user_name)
  end

  def reset_pword(username)
    new_pword = BCrypt::Password.create('jrpl').to_s
    sql = 'UPDATE users SET pword = $1 WHERE user_name = $2'
    query(sql, new_pword, username)
  end

  def load_user_credentials
    sql = 'SELECT user_name, pword, email FROM users'
    result = query(sql)

    result.each_with_object({}) do |tuple, hash|
      hash[tuple['user_name']] =
        { pword: tuple['pword'], email: tuple['email'] }
    end
  end

  def user_id(user_name)
    sql = 'SELECT user_id FROM users WHERE user_name = $1'
    result = query(sql, user_name)
    result.first['user_id'].to_i
  end

  def user_id_from_cookies(series_id, token)
    sql = 'SELECT user_id FROM remember_me WHERE series_id = $1 AND token = $2;'
    result = query(sql, series_id, token)
    return nil if result.ntuples == 0
    result.first['user_id'].to_i
  end

  def user_name_from_email(email)
    sql = 'SELECT user_name FROM users WHERE email = $1'
    result = query(sql, email)
    return nil if result.ntuples == 0
    result.first['user_name']
  end

  def load_user_details(user_id)
    sql = select_query_single_user
    result = query(sql, user_id)
    return nil if result.ntuples == 0
    result.map do |tuple|
      tuple_to_users_details_hash(tuple)
    end.first
  end

  def load_all_users_details
    sql = select_query_users_details()
    result = query(sql)
    result.map do |tuple|
      tuple_to_users_details_hash(tuple)
    end
  end

  def user_admin?(user_id)
    sql = 'SELECT * FROM user_role WHERE user_id = $1 AND role_id = $2;'
    result = query(sql, user_id, admin_id())
    !(result.ntuples == 0)
  end

  def assign_admin(user_id)
    sql = 'INSERT INTO user_role VALUES ($1, $2);'
    query(sql, user_id, admin_id())
  end

  def unassign_admin(user_id)
    sql = 'DELETE FROM user_role WHERE user_id = $1 AND role_id = $2;'
    query(sql, user_id, admin_id())
  end

  def series_id_list
    sql = 'SELECT series_id FROM remember_me;'
    result = query(sql)
    return [] if result.ntuples == 0
    result.map { |tuple| tuple['series_id'] }
  end

  def save_cookie_data(user_id, series_id_value, token_value)
    sql = 'INSERT INTO remember_me VALUES ($1, $2, $3, $4);'
    query(sql, user_id, series_id_value, token_value, Time.now)
  end

  def save_new_token(user_id, series_id_value, token_value)
    sql = <<~SQL
      UPDATE remember_me SET token = $1, date_added = $2
      WHERE user_id = $3 AND series_id = $4;
    SQL
    query(sql, token_value, Time.now, user_id, series_id_value)
  end

  def delete_cookie_data(series_id, token)
    sql = 'DELETE FROM remember_me WHERE series_id = $1 AND token = $2;'
    query(sql, series_id, token)
  end

  def load_all_matches(user_id)
    sql = construct_all_matches_query()
    result = query(sql, user_id)
    result.map do |tuple|
      tuple_to_matches_details_hash(tuple)
    end
  end

  def load_single_match(user_id, match_id)
    sql = construct_single_match_query()
    result = query(sql, user_id, match_id)
    result.map do |tuple|
      tuple_to_matches_details_hash(tuple)
    end.first
  end

  def delete_prediction(user_id, match_id)
    sql = 'DELETE FROM prediction WHERE user_id = $1 AND match_id = $2;'
    query(sql, user_id, match_id)
  end

  def add_prediction(user_id, match_id, home_team_points, away_team_points)
    delete_prediction(user_id, match_id)
    sql = insert_prediction_query
    query(sql, user_id, match_id, home_team_points, away_team_points)
  end

  def max_match_id
    sql = 'SELECT max(match_id) FROM match;'
    query(sql).first['max'].to_i
  end

  def min_match_id
    sql = 'SELECT min(match_id) FROM match;'
    query(sql).first['min'].to_i
  end

  def add_result(match_id, home_team_points, away_team_points, user_id)
    update_match_table(match_id, home_team_points, away_team_points, user_id)
  end

  def result_type(home_points, away_points)
    case home_points <=> away_points
    when 1  then 'home_win'
    when -1 then 'away_win'
    else         'draw'
    end
  end

  def predictions_for_match(match_id)
    sql = 'SELECT prediction_id, home_team_points, away_team_points FROM prediction WHERE match_id = $1;'
    result = query(sql, match_id)
    result.map do |tuple| 
      { prediction_id: tuple['prediction_id'].to_i,
        home_team_points: tuple['home_team_points'].to_i,
        away_team_points: tuple['away_team_points'].to_i }
    end
  end

  def match_result(match_id)
    sql = 'SELECT home_team_points, away_team_points FROM match WHERE match_id = $1;'
    result = query(sql, match_id)
    result.map do |tuple|
      { home_team_points: tuple['home_team_points'].to_i,
        away_team_points: tuple['away_team_points'].to_i }
    end.first
  end

  def prediction_id_in_points_table
    sql = 'SELECT prediction_id FROM points;'
    result = query(sql)
    result.map { |tuple| tuple['prediction_id'].to_i }
  end

  def insert_into_points_table(prediction_id, scoring_system_id, result_points, score_points)
    sql = <<~SQL
      INSERT INTO points 
      (prediction_id, scoring_system_id, result_points, score_points, total_points)
      VALUES
      ($1, $2, $3, $4, $5);
    SQL
    query(sql, prediction_id, 1, result_points, score_points, result_points + score_points)
  end

  def update_scoreboard(match_id)
    predictions = predictions_for_match(match_id)
    result = match_result(match_id)
    match_type = result_type(result[:home_team_points], result[:away_team_points])
    existing_predictions_scored = prediction_id_in_points_table()
    
    # Official scoring
    # For each prediction, work out result points and score points and update db
      # if prediciton_id already exists in points, update record
      # else create new record
    predictions.each do |prediction|
      prediction_type = result_type(prediction[:home_team_points], prediction[:away_team_points])
      result_points = ( match_type == prediction_type ? 1 : 0 )
      home_score_points = ( result[:home_team_points] == prediction[:home_team_points] ? 1 : 0 )
      away_score_points = ( result[:away_team_points] == prediction[:away_team_points] ? 1 : 0 )
      score_points = home_score_points + away_score_points
      if existing_predictions_scored.include?(prediction[:prediction_id])
        # update_points_table(prediction[:prediction_id], 1, result_points, score_points)
      else
        insert_into_points_table(prediction[:prediction_id], 1, result_points, score_points)
      end
    end
    # For each scoring system
      # Calculate result points
          # Determine result type - home win, away win, draw
   

    # end
          # Return 1 if result and prediction are the same type
      # Calculate score points
        # if home prediction and away predictions is the same as result
      # If points already contains that prediction_id for that system, update record
        # UPDATE TABLE points SET result points and score points WHERE preediction_id and scoring system id
      # Otherwise, create new points record
        # INSERT INTO points (prediction_id, scoring_system_id, result_points, score_points)
  end

  def tournament_stage_names
    sql = 'SELECT name FROM stage;'
    result = query(sql)
    result.map { |tuple| tuple['name'] }
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def filter_matches_list(user_id, criteria, lockdown)
    add_empty_strings_for_stages_for_exec_params(criteria)

    sql = construct_filter_matches_list_query(criteria)

    result = query(
      sql,
      lockdown[:date],
      lockdown[:time],
      criteria[:tournament_stages][0],
      criteria[:tournament_stages][1],
      criteria[:tournament_stages][2],
      criteria[:tournament_stages][3],
      criteria[:tournament_stages][4],
      criteria[:tournament_stages][5],
      user_id
    )

    result.map do |tuple|
      tuple['match_id'].to_i
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def filter_matches(user_id, criteria, lockdown)
    add_empty_strings_for_stages_for_exec_params(criteria)

    sql = construct_filter_matches_details_query(criteria)

    result = query(
      sql,
      lockdown[:date],
      lockdown[:time],
      criteria[:tournament_stages][0],
      criteria[:tournament_stages][1],
      criteria[:tournament_stages][2],
      criteria[:tournament_stages][3],
      criteria[:tournament_stages][4],
      criteria[:tournament_stages][5],
      user_id
    )

    result.map do |tuple|
      tuple_to_matches_details_hash(tuple)
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def convert_str_to_int(str)
    # This is needed because nil.to_i returns 0!!!
    str ? str.to_i : nil
  end

  def admin_id
    sql = 'SELECT role_id FROM role WHERE name = $1;'
    result = query(sql, 'Admin')
    result.first['role_id'].to_i
  end

  def select_query_single_user
    <<~SQL
      SELECT users.user_id, users.user_name, users.email, string_agg(role.name, ', ') AS roles
      FROM users
      FULL OUTER JOIN user_role ON users.user_id = user_role.user_id
      FULL OUTER JOIN role ON user_role.role_id = role.role_id
      WHERE users.user_id = $1
      GROUP BY users.user_id, users.user_name, users.email
      ORDER BY users.user_name;
    SQL
  end

  def select_query_users_details
    <<~SQL
      SELECT users.user_id, users.user_name, users.email, string_agg(role.name, ', ') AS roles
      FROM users
      FULL OUTER JOIN user_role ON users.user_id = user_role.user_id
      FULL OUTER JOIN role ON user_role.role_id = role.role_id
      GROUP BY users.user_id, users.user_name, users.email
      ORDER BY users.user_name;
    SQL
  end

  def tuple_to_users_details_hash(tuple)
    { user_id: tuple['user_id'].to_i,
      user_name: tuple['user_name'],
      email: tuple['email'],
      roles: tuple['roles'] }
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def tuple_to_matches_details_hash(tuple)
    { match_id: tuple['match_id'].to_i,
      match_date: tuple['date'],
      kick_off: tuple['kick_off'],
      home_team_points: convert_str_to_int(tuple['home_team_points']),
      away_team_points: convert_str_to_int(tuple['away_team_points']),
      home_team_prediction: convert_str_to_int(tuple['home_team_prediction']),
      away_team_prediction: convert_str_to_int(tuple['away_team_prediction']),
      home_team_name: tuple['home_team_name'],
      home_tournament_role: tuple['home_tournament_role'],
      home_team_short_name: tuple['home_team_short_name'],
      away_team_name: tuple['away_team_name'],
      away_tournament_role: tuple['away_tournament_role'],
      away_team_short_name: tuple['away_team_short_name'],
      stage: tuple['stage'],
      venue: tuple['venue'],
      broadcaster: tuple['broadcaster'] }
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def insert_prediction_query
    <<~SQL
      INSERT INTO prediction
        (user_id, match_id, home_team_points, away_team_points)
      VALUES ($1, $2, $3, $4);
    SQL
  end

  def select_match_id_clause
    'SELECT match.match_id'
  end

  def select_match_details_clause
    <<~SQL
    SELECT
      match.match_id,
      match.date,
      match.kick_off,
      predictions.home_team_points AS home_team_prediction,
      predictions.away_team_points AS away_team_prediction,
      match.home_team_points,
      match.away_team_points,
      home_team.name AS home_team_name,
      home_team.short_name AS home_team_short_name,
      away_team.name AS away_team_name,
      away_team.short_name AS away_team_short_name,
      home_tr.name AS home_tournament_role,
      away_tr.name AS away_tournament_role,
      stage.name AS stage,
      venue.name AS venue,
      broadcaster.name AS broadcaster
    SQL
  end

  def select_user_predictions_clause
    <<~SQL
      , predictions.home_team_points AS home_team_prediction,
      predictions.away_team_points AS away_team_prediction
    SQL
  end

  def from_match_details_clause
    <<~SQL
    FROM match
      INNER JOIN tournament_role AS home_tr ON match.home_team_id = home_tr.tournament_role_id
      INNER JOIN tournament_role AS away_tr ON match.away_team_id = away_tr.tournament_role_id
      LEFT OUTER JOIN team AS home_team ON home_tr.team_id = home_team.team_id
      LEFT OUTER JOIN team AS away_team ON away_tr.team_id = away_team.team_id
      INNER JOIN venue ON match.venue_id = venue.venue_id
      INNER JOIN stage ON match.stage_id = stage.stage_id
      INNER JOIN broadcaster ON match.broadcaster_id = broadcaster.broadcaster_id
    SQL
  end

  def predictions_for_single_user_single_or_all_matches_clause
    <<~SQL
      LEFT OUTER JOIN
        (SELECT prediction.match_id, prediction.home_team_points, prediction.away_team_points
          FROM prediction
          WHERE prediction.user_id = $1)
      AS predictions ON predictions.match_id = match.match_id
    SQL
  end

  def predictions_for_single_user_filter_clause
    <<~SQL
      LEFT OUTER JOIN
        (SELECT prediction.match_id, prediction.home_team_points, prediction.away_team_points
          FROM prediction
          WHERE prediction.user_id = $9)
      AS predictions ON predictions.match_id = match.match_id
    SQL
  end

  def where_single_match_clause
    'WHERE match.match_id = $2'
  end

  def lockdown_clause(match_status)
    case match_status
    when 'locked_down'
      '(date < $1::date OR (date = $1::date AND kick_off < $2::time))'
    when 'not_locked_down'
      '(date > $1::date OR (date = $1::date AND kick_off >= $2::time))'
    else
      '$1 != $2'
    end
  end

  def tournament_stages_clause
    'AND (stage.name IN ($3, $4, $5, $6, $7, $8))'
  end

  def predictions_clause(prediction_status)
    case prediction_status
    when 'predicted'
      'AND (predictions.match_id IS NOT NULL)'
    when 'not_predicted'
      'AND (predictions.match_id IS NULL)'
    else
      ''
    end
  end

  def add_empty_strings_for_stages_for_exec_params(criteria)
    number_of_stages = tournament_stage_names.size
    while criteria[:tournament_stages].size < number_of_stages
      criteria[:tournament_stages] << ''
    end
  end

  def order_clause
    'ORDER BY match.date, match.kick_off, match.match_id;'
  end

  def construct_all_matches_query
    [
      select_match_details_clause(),
      select_user_predictions_clause(),
      from_match_details_clause(),
      predictions_for_single_user_single_or_all_matches_clause(),
      order_clause()
    ].join(' ')
  end

  def construct_single_match_query
    [
      select_match_details_clause(),
      select_user_predictions_clause(),
      from_match_details_clause(),
      predictions_for_single_user_single_or_all_matches_clause(),
      where_single_match_clause(),
      order_clause()
    ].join(' ')
  end

  def construct_filter_matches_list_query(criteria)
    [
      select_match_id_clause(),
      from_match_details_clause(),
      predictions_for_single_user_filter_clause(),
      'WHERE',
      lockdown_clause(criteria[:match_status]),
      tournament_stages_clause(),
      predictions_clause(criteria[:prediction_status]),
      order_clause()
    ].join(' ')
  end

  def construct_filter_matches_details_query(criteria)
    [
      select_match_details_clause(),
      from_match_details_clause(),
      predictions_for_single_user_filter_clause(),
      'WHERE',
      lockdown_clause(criteria[:match_status]),
      tournament_stages_clause(),
      predictions_clause(criteria[:prediction_status]),
      order_clause()
    ].join(' ')
  end

  
  def update_match_table(match_id, home_team_points, away_team_points, user_id)
    sql = <<~SQL
      UPDATE match
      SET
        home_team_points = $1,
        away_team_points = $2,
        result_posted_by = $3,
        result_posted_on = $4
      WHERE match_id = $5;
    SQL
    query(sql, home_team_points, away_team_points, user_id, Time.now, match_id)
  end
end
