module DBPersMatches
  def add_result(match_id, home_team_points, away_team_points, user_id)
    sql = update_match_table_query()
    query(sql, home_team_points, away_team_points, user_id, Time.now, match_id)
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

  def match_result(match_id)
    sql = match_result_query()
    result = query(sql, match_id)
    result.map do |tuple|
      { home_pts: tuple['home_team_points'].to_i,
        away_pts: tuple['away_team_points'].to_i }
    end.first
  end

  def max_match_id
    sql = 'SELECT max(match_id) FROM match;'
    query(sql).first['max'].to_i
  end

  def min_match_id
    sql = 'SELECT min(match_id) FROM match;'
    query(sql).first['min'].to_i
  end

  private

  def add_empty_strings_for_stages_for_exec_params(criteria)
    number_of_stages = tournament_stage_names.size
    while criteria[:tournament_stages].size < number_of_stages
      criteria[:tournament_stages] << ''
    end
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

  def match_result_query
    'SELECT home_team_points, away_team_points FROM match WHERE match_id = $1;'
  end

  def order_clause
    'ORDER BY match.date, match.kick_off, match.match_id;'
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

  def predictions_for_single_user_filter_clause
    <<~SQL
      LEFT OUTER JOIN
        (SELECT prediction.match_id, prediction.home_team_points, prediction.away_team_points
          FROM prediction
          WHERE prediction.user_id = $9)
      AS predictions ON predictions.match_id = match.match_id
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

  def select_match_id_clause
    'SELECT match.match_id'
  end

  def select_user_predictions_clause
    <<~SQL
      , predictions.home_team_points AS home_team_prediction,
      predictions.away_team_points AS away_team_prediction
    SQL
  end

  def tournament_stages_clause
    'AND (stage.name IN ($3, $4, $5, $6, $7, $8))'
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def tuple_to_matches_details_hash(tuple)
    { match_id: tuple['match_id'].to_i,
      match_date: tuple['date'],
      kick_off: tuple['kick_off'],
      home_pts: convert_str_to_int(tuple['home_team_points']),
      away_pts: convert_str_to_int(tuple['away_team_points']),
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

  def update_match_table_query
    <<~SQL
      UPDATE match
      SET
        home_team_points = $1,
        away_team_points = $2,
        result_posted_by = $3,
        result_posted_on = $4
      WHERE match_id = $5;
    SQL
  end

  def where_single_match_clause
    'WHERE match.match_id = $2'
  end
end
