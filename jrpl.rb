require 'bcrypt'
require 'pry'
require 'securerandom'
require 'sinatra'
require 'sinatra/cookies'
require 'tilt/erubis'

require_relative 'database_persistence'
require_relative 'loginable'
require_relative 'login_cookies'
require_relative 'jrpl_route_errors'
require_relative 'jrpl_route_helpers'
require_relative 'jrpl_view_helpers'

# Constant definitions
LOCKDOWN_BUFFER = 30 * 60 # 30 minutes

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, escape_html: true
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'database_persistence.rb'
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
end

helpers do
  # Route helper methods
  include Loginable
  include LoginCookies
  include RouteErrors
  include RouteHelpers

  # View helper methods
  include ViewHelpers
end

# Routes
get '/' do
  user_signed_in?
  erb :home
end

get '/match/:match_id' do
  require_signed_in_user
  match_id = params[:match_id].to_i
  if session[:criteria].nil?
    session[:criteria] = set_criteria_to_all_matches()
  end
  @match = @storage.load_single_match(session[:user_id], match_id)
  @match[:locked_down] = match_locked_down?(@match)
  # session[:message] = 'Match locked down!' if @match[:locked_down]
  erb :match_details
end

post '/match/add_prediction' do
  require_signed_in_user
  match_id = params[:match_id].to_i
  @match = @storage.load_single_match(session[:user_id], match_id)
  home_prediction = params[:home_team_prediction].to_f
  away_prediction = params[:away_team_prediction].to_f
  session[:message] = prediction_error(@match, home_prediction, away_prediction)
  if session[:message]
    status 422
    erb :match_details
  else
    @storage.add_prediction(
      session[:user_id],
      match_id,
      home_prediction.to_i,
      away_prediction.to_i
    )
    session[:message] = 'Prediction submitted.'
    redirect "/match/#{match_id}"
  end
end

post '/match/add_result' do
  require_signed_in_as_admin
  home_points = params[:home_pts].to_f
  away_points = params[:away_pts].to_f
  match_id = params[:match_id].to_i
  @match = @storage.load_single_match(session[:user_id], match_id)
  session[:message] = match_result_error(@match, home_points, away_points)
  if session[:message]
    status 422
    erb :match_details
  else
    @storage.add_result(
      match_id, home_points.to_i, away_points.to_i, session[:user_id]
    )
    update_scoreboard(match_id)
    session[:message] = 'Result submitted.'
    redirect "/match/#{match_id}"
  end
end

get '/matches/all' do
  require_signed_in_user
  session[:criteria] = set_criteria_to_all_matches()
  @matches = load_matches()
  @stage_names = @storage.tournament_stage_names()
  erb :matches_list do
    erb :match_filter_form
  end
end

get '/matches/filter_form' do
  require_signed_in_user
  erb :match_filter_form
end

post '/matches/filter' do
  require_signed_in_user
  @stage_names = @storage.tournament_stage_names()
  session[:criteria] = extract_search_criteria(params)
  @matches = load_matches()
  if @matches.empty?
    session[:message] = 'No matches meet your criteria, please try again!'
  end
  erb :matches_list do
    erb :match_filter_form
  end
end

get '/scoreboard' do
  @scoring_system = 'official'
  @scores = @storage.load_scoreboard_data(@scoring_system)
  erb :scoreboard
end

get '/toggle_scoring_system' do
  @scoring_system = params[:scoring_system]
  @scores = @storage.load_scoreboard_data(@scoring_system)
  erb :scoreboard
end

get '/users/administer_accounts' do
  require_signed_in_as_admin
  @users = @storage.load_all_users_details
  erb :administer_accounts
end

get '/users/edit_credentials' do
  require_signed_in_user
  erb :edit_credentials
end

post '/users/edit_credentials' do
  require_signed_in_user
  current_pword = params[:current_pword].strip
  new_user_details = extract_user_details(params)
  session[:message] = edit_login_error(new_user_details, current_pword)
  if session[:message].empty?
    update_user_credentials(new_user_details)
    redirect '/'
  else
    status 422
    erb :edit_credentials
  end
end

post '/users/reset_pword' do
  require_signed_in_as_admin
  user_name = params[:user_name]
  @storage.reset_pword(user_name)
  session[:message] =
    "The password has been reset to 'jrpl' for #{user_name}."
  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    '/'
  else
    redirect '/'
  end
end

get '/users/signin' do
  require_signed_out_user
  erb :signin
end

post '/users/signin' do
  require_signed_out_user
  session[:intended_route] = params['intended_route']
  user_name = extract_user_name(params[:login].strip)
  pword = params[:pword].strip
  if valid_credentials?(user_name, pword)
    user_id = @storage.user_id(user_name)
    setup_user_session_data(user_id)
    if params.keys.include?('remember_me')
      implement_cookies()
    end
    session[:message] = 'Welcome!'
    redirect(session[:intended_route])
  else
    session[:message] = 'Invalid credentials.'
    status 422
    erb :signin
  end
end

post '/users/signout' do
  require_signed_in_user
  @storage.delete_cookie_data(cookies[:series_id], cookies[:token])
  session.clear
  session[:message] = 'You have been signed out.'
  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    '/'
  else
    redirect '/'
  end
end

get '/users/signup' do
  require_signed_out_user
  erb :signup
end

post '/users/signup' do
  require_signed_out_user
  session[:intended_route] = params[:intended_route]
  new_user_details = extract_user_details(params)
  session[:message] = signup_input_error(new_user_details)
  if session[:message].empty?
    @storage.upload_new_user_credentials(new_user_details)
    user_id = @storage.user_id(new_user_details[:user_name])
    setup_user_session_data(user_id)
    if params.keys.include?('remember_me')
      implement_cookies()
    end
    session[:message] = 'Your account has been created.'
    redirect(session[:intended_route])
  else
    status 422
    erb :signup
  end
end

post '/users/toggle_admin' do
  require_signed_in_as_admin
  user_id = params[:user_id].to_i
  button = params[:button]
  if button == 'grant_admin' && !@storage.user_admin?(user_id)
    @storage.assign_admin(user_id)
  elsif button == 'revoke_admin' && @storage.user_admin?(user_id)
    @storage.unassign_admin(user_id)
  end
  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    '/users/administer_accounts'
  else
    redirect '/users/administer_accounts'
  end
end

not_found do
  redirect '/'
end
