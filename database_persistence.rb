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

  def upload_new_user_credentials(first_name, last_name, display_name, user_name, password)
    hashed_password = BCrypt::Password.create(password).to_s
    sql = 'INSERT INTO users (first_name, last_name, display_name, email, pword) VALUES ($1, $2, $3, $4, $5)'
    query(sql, first_name, last_name, display_name, user_name, hashed_password)
  end

  def change_username_and_password(old_username, new_username, new_password)
    hashed_password = BCrypt::Password.create(new_password).to_s
    sql = 'UPDATE users SET email = $1, pword = $2 WHERE email = $3'
    query(sql, new_username, hashed_password, old_username)
  end

  def change_username(old_username, new_username)
    sql = 'UPDATE users SET email = $1 WHERE email = $2'
    query(sql, new_username, old_username)
  end

  def change_password(old_username, new_password)
    hashed_password = BCrypt::Password.create(new_password).to_s
    sql = 'UPDATE users SET pword = $1 WHERE email = $2'
    query(sql, hashed_password, old_username)
  end

  def reset_password(username)
    new_password = BCrypt::Password.create('jrpl').to_s
    sql = 'UPDATE users SET pword = $1 WHERE email = $2'
    query(sql, new_password, username)
  end

  def load_user_credentials
    sql = 'SELECT email, pword FROM users'
    result = query(sql)

    result.each_with_object({}) do |tuple, hash|
      hash[tuple['email']] = tuple['pword']
    end
  end

  def user_id(user_name)
    sql = 'SELECT user_id FROM users WHERE email = $1'
    result = query(sql, user_name)
    result.first['user_id'].to_i
  end

  def all_users_list
    sql = <<~SQL
      SELECT
        user_id,
        first_name,
        last_name,
        display_name,
        email,
        pword
      FROM users
      ORDER BY display_name;
    SQL
    result = query(sql)
    result.map do |tuple|
      tuple_to_user_list_hash(tuple)
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

  def tuple_to_user_list_hash(tuple)
    { user_id: tuple['user_id'].to_i,
      first_name: tuple['first_name'],
      last_name: tuple['last_name'],
      display_name: tuple['display_name'],
      email: tuple['email'],
      pword: tuple['pword'] }
  end
end
