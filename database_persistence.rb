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

  def load_all_matches
    sql = <<~SQL
      SELECT match.match_id, match.date, match.kick_off,
      home_team.name AS home_team_name, home_team.short_name AS home_team_short_name, 
      away_team.name AS away_team_name, away_team.short_name AS away_team_short_name, 
      stage.name AS stage, venue.name AS venue, broadcaster.name AS broadcaster
      FROM match
      LEFT OUTER JOIN tournament_role AS home_tr ON match.home_team_id = home_tr.team_id
      LEFT OUTER JOIN tournament_role AS away_tr ON match.away_team_id = away_tr.team_id
      FULL OUTER JOIN team AS home_team ON home_tr.team_id = home_team.team_id
      FULL OUTER JOIN team AS away_team ON away_tr.team_id = away_team.team_id
      LEFT OUTER JOIN venue ON match.venue_id = venue.venue_id
      LEFT OUTER JOIN stage ON match.stage_id = stage.stage_id
      LEFT OUTER JOIN broadcaster ON match.broadcaster_id = broadcaster.broadcaster_id
      ORDER BY match.date, match.kick_off, match.match_id;
    SQL
    result = query(sql)
    result.map do |tuple| 
      tuple_to_matches_details_hash(tuple)
    end
  end

  # SELECT match.match_id, match.date, match.kick_off,
  # home_team.name, home_team.short_name, away_team.name, away_team.short_name, 
  # stage.name, venue.name, broadcaster.name
  # FROM match
  # INNER JOIN tournament_role AS home_tr ON match.home_team_id = home_tr.team_id
  # INNER JOIN tournament_role AS away_tr ON match.away_team_id = away_tr.team_id
  # INNER JOIN team AS home_team ON home_tr.team_id = home_team.team_id
  # INNER JOIN team AS away_team ON away_tr.team_id = away_team.team_id
  # INNER JOIN stage ON match.stage_id = stage.stage_id
  # INNER JOIN venue ON match.venue_id = venue.venue_id
  # INNER JOIN broadcaster ON match.broadcaster_id = broadcaster.broadcaster_id;

  private

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def convert_string_to_integer(str)
    # This is needed because nil.to_i returns 0!!!
    str ? str.to_i : nil
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
  
  def admin_id
    sql = 'SELECT role_id FROM role WHERE name = $1;'
    result = query(sql, 'Admin')
    result.first['role_id'].to_i
  end
  
  def tuple_to_matches_details_hash(tuple)
    { match_id: tuple['match_id'].to_i,
      match_date: tuple['date'],
      kick_off: tuple['kick_off'],
      home_team_name: tuple['home_team_name'],
      home_team_short_name: tuple['home_team_short_name'],
      away_team_name: tuple['away_team_name'],
      away_team_short_name: tuple['away_team_short_name'],
      stage: tuple['stage'],
      venue: tuple['venue'],
      broadcaster: tuple['broadcaster'] }
  end
end
