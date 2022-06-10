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

  def user_email(user_name)
    sql = 'SELECT email FROM users WHERE user_name = $1'
    result = query(sql, user_name)
    result.first['email']
  end

  def user_role(user_id)
    sql = <<~SQL
      SELECT role.name FROM role
      INNER JOIN user_role ON role.role_id = user_role.role_id
      INNER JOIN users ON user_role.user_id = users.user_id
      WHERE users.user_id = $1
    SQL
    result = query(sql, user_id)
    return '' if result.ntuples == 0
    result.first['name']
  end

  def user_name_from_email(email)
    sql = 'SELECT user_name FROM users WHERE email = $1'
    result = query(sql, email)
    return nil if result.ntuples == 0
    result.first['user_name']
  end

  def load_users_details
    sql = <<~SQL
      SELECT users.user_name, users.email, string_agg(role.name, ', ') AS roles
      FROM users
      FULL OUTER JOIN user_role ON users.user_id = user_role.user_id
      FULL OUTER JOIN role ON user_role.role_id = role.role_id
      GROUP BY users.user_name, users.email
      ORDER BY users.user_name;
    SQL
    result = query(sql)
    result.map do |tuple|
      tuple_to_users_details_hash(tuple)
    end
  end

  private

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def convert_string_to_integer(str)
    # This is needed because nil.to_i returns 0!!!
    str ? str.to_i : nil
  end

  def tuple_to_users_details_hash(tuple)
    { user_name: tuple['user_name'],
      email: tuple['email'],
      roles: tuple['roles'] }
  end
end
