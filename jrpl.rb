require 'bcrypt'
require 'pry'
require 'securerandom'
require 'sinatra'
require 'sinatra/cookies'
require 'tilt/erubis'

require_relative 'database_persistence'
require_relative 'loginable'

include Loginable

configure do
  enable :sessions
  set :session_secret, 'secret'
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

# Constant definitions
LOCKDOWN_BUFFER = 30 * 60 # 30 minutes

# Helper methods for view templates
# rubocop:disable Metrics/BlockLength
helpers do
  def home_team_name(match)
    if match[:home_team_name].nil?
      match[:home_tournament_role]
    else
      match[:home_team_name]
    end
  end

  def away_team_name(match)
    if match[:away_team_name].nil?
      match[:away_tournament_role]
    else
      match[:away_team_name]
    end
  end

  def home_team_prediction(match)
    prediction = match[:home_team_prediction]
    if prediction.nil?
      'no prediction'
    else
      prediction
    end
  end

  def away_team_prediction(match)
    prediction = match[:away_team_prediction]
    if prediction.nil?
      'no prediction'
    else
      prediction
    end
  end

  def home_team_points(match)
    if match[:home_pts].nil?
      'no result'
    else
      match[:home_pts]
    end
  end

  def away_team_points(match)
    if match[:away_pts].nil?
      'no result'
    else
      match[:away_pts]
    end
  end

  def match_locked_down?(match)
    match_date_time = "#{match[:match_date]} #{match[:kick_off]}"
    (Time.now + LOCKDOWN_BUFFER) > Time.parse(match_date_time)
  end

  def previous_match(match_id)
    match_list = load_match_list()
    current_match_index = match_list.index { |match| match == match_id }
    current_match_index = 1 if current_match_index.nil?
    previous_match_index = current_match_index - 1
    if previous_match_index < 0
      nil
    else
      match_list[previous_match_index]
    end
  end

  def next_match(match_id)
    match_list = load_match_list()
    max_index = match_list.size - 1
    current_match_index = match_list.index { |match| match == match_id }
    current_match_index = 1 if current_match_index.nil?
    next_match_index = current_match_index + 1
    if next_match_index > max_index
      nil
    else
      match_list[next_match_index]
    end
  end
end
# rubocop:enable Metrics/BlockLength

# Helper methods for routes

def not_integer?(num)
  !(num.floor - num).zero?
end

def prediction_type_error(home_prediction, away_prediction)
  error = []
  error << 'integers' if
    not_integer?(home_prediction) || not_integer?(away_prediction)
  error << 'non-negative' if
    home_prediction < 0 || away_prediction < 0
  return nil if error.empty?
  "Your predictions must be #{error.join(' and ')}."
end

def prediction_error(match, home_prediction, away_prediction)
  if match_locked_down?(match)
    'You cannot add or change your prediction because ' \
    'this match is already locked down!'
  else
    prediction_type_error(home_prediction, away_prediction)
  end
end

def match_result_type_error(home_points, away_points)
  error = []
  error << 'integers' if
    not_integer?(home_points) || not_integer?(away_points)
  error << 'non-negative' if
    home_points < 0 || away_points < 0
  return nil if error.empty?
  "Match results must be #{error.join(' and ')}."
end

def match_result_error(match, home_points, away_points)
  if !match_locked_down?(match)
    'You cannot add or change the match result because ' \
    'this match has not yet been played.'
  else
    match_result_type_error(home_points, away_points)
  end
end

def extract_tournament_stages(params)
  params.select { |_, v| v == 'tournament_stage' }.keys
end

def extract_search_criteria(params)
  { match_status: params[:match_status],
    prediction_status: params[:prediction_status],
    tournament_stages: extract_tournament_stages(params) }
end

def set_criteria_to_all_matches
  { match_status: 'all',
    prediction_status: 'all',
    tournament_stages: @storage.tournament_stage_names }
end

def calculate_lockdown
  lockdown_timedate = Time.now + LOCKDOWN_BUFFER
  lockdown_date = lockdown_timedate.strftime("%Y-%m-%d")
  lockdown_time = lockdown_timedate.strftime("%k:%M:%S")
  { date: lockdown_date, time: lockdown_time }
end

def load_match_list
  lockdown = calculate_lockdown
  @storage.filter_matches_list(session[:user_id], session[:criteria], lockdown)
end

def load_matches
  lockdown = calculate_lockdown
  @storage.filter_matches(session[:user_id], session[:criteria], lockdown)
end

def result_type(home_points, away_points)
  case home_points <=> away_points
  when 1  then 'home_win'
  when -1 then 'away_win'
  else         'draw'
  end
end

def update_official_scoring(result, match_type, predictions)
  scoring_id = @storage.id_for_scoring_system('official')
  predictions.each do |pred|
    pred_type = result_type(pred[:home_pts], pred[:away_pts])
    result_pts = (match_type == pred_type ? 1 : 0)
    home_score_pts = (result[:home_pts] == pred[:home_pts] ? 1 : 0)
    away_score_pts = (result[:away_pts] == pred[:away_pts] ? 1 : 0)
    score_pts = home_score_pts + away_score_pts
    @storage.add_user_points(pred[:pred_id], scoring_id, result_pts, score_pts)
  end
end

def update_autoquiz_scoring(result, match_type, predictions)
  scoring_id = @storage.id_for_scoring_system('autoquiz')
  predictions.each do |pred|
    pred_type = result_type(pred[:home_pts], pred[:away_pts])
    result_pts = (match_type == pred_type ? 2 : 0)
    home_score_pts = (result[:home_pts] == pred[:home_pts] ? 2 : 0)
    away_score_pts = (result[:away_pts] == pred[:away_pts] ? 2 : 0)
    score_pts = home_score_pts + away_score_pts
    @storage.add_user_points(pred[:pred_id], scoring_id, result_pts, score_pts)
  end
end

def update_scoreboard(match_id)
  result = @storage.match_result(match_id)
  match_type = result_type(result[:home_pts], result[:away_pts])
  predictions = @storage.predictions_for_match(match_id)

  update_official_scoring(result, match_type, predictions)
  update_autoquiz_scoring(result, match_type, predictions)
end

# Routes
get '/' do
  user_signed_in?
  erb :home
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

get '/users/administer_accounts' do
  require_signed_in_as_admin
  @users = @storage.load_all_users_details
  erb :administer_accounts
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

not_found do
  redirect '/'
end
