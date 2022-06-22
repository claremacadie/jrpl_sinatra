module DBPersPredictions
  def add_prediction(user_id, match_id, home_team_points, away_team_points)
    delete_prediction(user_id, match_id)
    sql = insert_prediction_query()
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

  private

  def delete_prediction(user_id, match_id)
    sql = 'DELETE FROM prediction WHERE user_id = $1 AND match_id = $2;'
    query(sql, user_id, match_id)
  end

  def insert_prediction_query
    <<~SQL
      INSERT INTO prediction
        (user_id, match_id, home_team_points, away_team_points)
      VALUES ($1, $2, $3, $4);
    SQL
  end

  def predictions_for_match_query
    <<~SQL
      SELECT prediction_id, home_team_points, away_team_points
      FROM prediction
      WHERE match_id = $1;
    SQL
  end
end