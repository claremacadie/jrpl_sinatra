module DBPersCookies
  def delete_cookie_data(series_id, token)
    sql = 'DELETE FROM remember_me WHERE series_id = $1 AND token = $2;'
    query(sql, series_id, token)
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

  def series_id_list
    sql = 'SELECT series_id FROM remember_me;'
    result = query(sql)
    return [] if result.ntuples == 0
    result.map { |tuple| tuple['series_id'] }
  end

  def user_id_from_cookies(series_id, token)
    sql = 'SELECT user_id FROM remember_me WHERE series_id = $1 AND token = $2;'
    result = query(sql, series_id, token)
    return nil if result.ntuples == 0
    result.first['user_id'].to_i
  end
end
