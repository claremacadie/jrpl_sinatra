require 'pg'

require_relative 'login_db_pers'
require_relative 'db_pers_matches'

class DatabasePersistence
  include LoginDBPers
  include DBPersMatches

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

  def delete_prediction(user_id, match_id)
    sql = 'DELETE FROM prediction WHERE user_id = $1 AND match_id = $2;'
    query(sql, user_id, match_id)
  end

  def add_prediction(user_id, match_id, home_team_points, away_team_points)
    delete_prediction(user_id, match_id)
    sql = insert_prediction_query
    query(sql, user_id, match_id, home_team_points, away_team_points)
  end

  def predictions_for_match(match_id)
    sql = predictions_for_match_query()
    result = query(sql, match_id)
    result.map do |tuple|
      { pred_id: tuple['prediction_id'].to_i,
        home_pts: tuple['home_team_points'].to_i,
        away_pts: tuple['away_team_points'].to_i }
    end
  end

  def add_user_points(pred_id, scoring_system_id, result_pts, score_pts)
    delete_existing_points_entry(pred_id, scoring_system_id)
    sql = insert_into_points_table_query()
    query(
      sql,
      pred_id,
      scoring_system_id,
      result_pts,
      score_pts,
      result_pts + score_pts
    )
  end

  def tournament_stage_names
    sql = 'SELECT name FROM stage;'
    result = query(sql)
    result.map { |tuple| tuple['name'] }
  end

  def id_for_scoring_system(scoring_system)
    sql = 'SELECT scoring_system_id FROM scoring_system WHERE name = $1;'
    query(sql, scoring_system).map do |tuple|
      tuple['scoring_system_id']
    end.first.to_i
  end

  def load_scoreboard_data(scoring_system)
    scoring_system_id = id_for_scoring_system(scoring_system)
    sql = select_users_points_query()
    result = query(sql, scoring_system_id)
    result.map do |tuple|
      { user_id: tuple['user_id'],
        user_name: tuple['user_name'],
        result_points: tuple['result_points'].to_i,
        score_points: tuple['score_points'].to_i }
    end
  end

  private

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def convert_str_to_int(str)
    # This is needed because nil.to_i returns 0!!!
    str ? str.to_i : nil
  end

  def insert_prediction_query
    <<~SQL
      INSERT INTO prediction
        (user_id, match_id, home_team_points, away_team_points)
      VALUES ($1, $2, $3, $4);
    SQL
  end
  
  def update_points_table_query
    <<~SQL
      UPDATE points
      SET result_points = $1, score_points = $2, total_points = $3
      WHERE (prediction_id = $4 AND scoring_system_id = $5);
    SQL
  end

  def insert_into_points_table_query
    <<~SQL
      INSERT INTO points
      (prediction_id, scoring_system_id, result_points, score_points, total_points)
      VALUES ($1, $2, $3, $4, $5);
    SQL
  end

  def select_users_points_query
    <<~SQL
      SELECT
        users.user_id,
        users.user_name,
        COALESCE(sum(system_points.result_points), 0) AS result_points,
        COALESCE(sum(system_points.score_points), 0) AS score_points,
        COALESCE(sum(system_points.total_points), 0) AS total_points
      FROM users
      LEFT OUTER JOIN prediction ON users.user_id = prediction.user_id
      LEFT OUTER JOIN
        (SELECT * FROM points WHERE scoring_system_id = $1) AS system_points
        ON prediction.prediction_id = system_points.prediction_id
      GROUP BY users.user_id
      ORDER BY total_points DESC, score_points DESC, result_points DESC, user_name;
    SQL
  end

  def match_result_query
    'SELECT home_team_points, away_team_points FROM match WHERE match_id = $1;'
  end

  def predictions_for_match_query
    <<~SQL
      SELECT prediction_id, home_team_points, away_team_points
      FROM prediction
      WHERE match_id = $1;
    SQL
  end

  def delete_existing_points_entry(pred_id, scoring_system_id)
    sql = <<~SQL
      DELETE FROM points
      WHERE prediction_id = $1 AND scoring_system_id = $2;
    SQL
    query(sql, pred_id, scoring_system_id)
  end
end
