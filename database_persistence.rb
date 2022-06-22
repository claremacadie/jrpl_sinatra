require 'pg'

require_relative 'db_pers_login'
require_relative 'db_pers_matches'
require_relative 'db_pers_points'
require_relative 'db_pers_predictions'

class DatabasePersistence
  include DBPersLogin
  include DBPersMatches
  include DBPersPoints
  include DBPersPredictions

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

  def tournament_stage_names
    sql = 'SELECT name FROM stage;'
    result = query(sql)
    result.map { |tuple| tuple['name'] }
  end

  private

  def convert_str_to_int(str)
    # This is needed because nil.to_i returns 0!!!
    str ? str.to_i : nil
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
end
