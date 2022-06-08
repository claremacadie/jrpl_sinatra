require 'pg'
	
class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: 'jrpl')
    @logger = logger
  end

  def disconnect
    @db.close
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