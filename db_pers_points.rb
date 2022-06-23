module DBPersPoints
  def add_points(pred_id, scoring_system_id, result_pts, score_pts)
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

  def delete_existing_points_entry(pred_id, scoring_system_id)
    sql = <<~SQL
      DELETE FROM points
      WHERE prediction_id = $1 AND scoring_system_id = $2;
    SQL
    query(sql, pred_id, scoring_system_id)
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

  def update_points_table_query
    <<~SQL
      UPDATE points
      SET result_points = $1, score_points = $2, total_points = $3
      WHERE (prediction_id = $4 AND scoring_system_id = $5);
    SQL
  end
end
