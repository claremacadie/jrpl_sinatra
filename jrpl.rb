require 'bcrypt'
require 'pry'
require 'securerandom'
require 'sinatra'
require 'sinatra/cookies'
require 'tilt/erubis'
require_relative 'database_persistence'

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

  def home_team_prediction(match_id)
    prediction = @storage.home_team_prediction(match_id, session[:user_id])
    if prediction.nil?
      'no prediction'
    else
      prediction
    end
  end

  def away_team_prediction(match_id)
    prediction = @storage.away_team_prediction(match_id, session[:user_id])
    if prediction.nil?
      'no prediction'
    else
      prediction
    end
  end

  def home_team_points(match)
    if match[:home_team_points].nil?
      'no result'
    else
      match[:home_team_points]
    end
  end

  def away_team_points(match)
    if match[:away_team_points].nil?
      'no result'
    else
      match[:away_team_points]
    end
  end

  def previous_match(match_id)
    match_list = @storage.match_list
    max_index = match_list.size - 1
    current_match_index = match_list.index(match_id: match_id)
    previous_match_index = current_match_index - 1
    if previous_match_index < 0
      match_list[max_index][:match_id]
    else
      match_list[previous_match_index][:match_id]
    end
  end

  def next_match(match_id)
    match_list = @storage.match_list
    max_index = match_list.size - 1
    current_match_index = match_list.index(match_id: match_id)
    next_match_index = current_match_index + 1
    if next_match_index > max_index
      match_list[0][:match_id]
    else
      match_list[next_match_index][:match_id]
    end
  end
end
# rubocop:enable Metrics/BlockLength

# Helper methods for routes
def setup_user_session_data(user_id)
  user_details = @storage.load_user_details(user_id)
  session[:user_id] = user_id
  session[:user_name] = user_details[:user_name]
  session[:user_email] = user_details[:email]
  session[:user_roles] = user_details[:roles]
end

def unique_random_string
  random_string = SecureRandom.hex(32)
  while @storage.series_id_list.include?(random_string)
    random_string = SecureRandom.hex(32)
  end
  random_string
end

def set_series_id_cookie
  series_id_value = unique_random_string()
  response.set_cookie(
    'series_id',
    { value: series_id_value,
      path: '/',
      expires: Time.now + (30 * 24 * 60 * 60) } # one month from now
  )
end

def set_token_cookie
  token_value = SecureRandom.hex(32)
  response.set_cookie(
    'token',
    { value: token_value,
      path: '/',
      expires: Time.now + (30 * 24 * 60 * 60) } # one month from now
  )
end

def implement_cookies
  set_series_id_cookie()
  set_token_cookie()
  @storage.save_cookie_data(
    session[:user_id],
    cookies[:series_id],
    cookies[:token]
  )
end

def reset_cookie_token
  set_token_cookie()
  @storage.save_new_token(
    session[:user_id],
    cookies[:series_id],
    cookies[:token]
  )
end

def signin_with_cookie
  return false unless cookies[:series_id] && cookies[:token]
  user_id = @storage.user_id_from_cookies(cookies[:series_id], cookies[:token])
  return false unless user_id
  setup_user_session_data(user_id)
  reset_cookie_token()
end

def user_signed_in?
  session.key?(:user_name) || signin_with_cookie()
end

def user_is_admin?
  # &. Safe navigation - checks object exists before invoking the method
  session[:user_roles]&.include?('Admin')
end

def require_signed_in_as_admin
  return if user_signed_in? && user_is_admin?
  session[:intended_route] = request.path_info
  session[:message] = 'You must be an administrator to do that.'
  redirect '/'
end

def require_signed_in_user
  return if user_signed_in?
  session[:message] = 'You must be signed in to do that.'
  redirect '/users/signin'
end

def require_signed_out_user
  return unless user_signed_in?
  session[:message] = 'You must be signed out to do that.'
  redirect '/'
end

def email_list
  @storage.load_user_credentials.values.each_with_object([]) do |hash, arr|
    arr << hash[:email]
  end
end

def extract_user_name(login)
  @storage.user_name_from_email(login) || login
end

def valid_credentials?(user_name, pword)
  credentials = @storage.load_user_credentials
  if credentials.key?(user_name)
    bcrypt_pword = BCrypt::Password.new(credentials[user_name][:pword])
    bcrypt_pword == pword
  else
    false
  end
end

def extract_user_details(params)
  { user_name: params[:new_user_name].strip,
    email: params[:new_email].strip,
    pword: params[:new_pword].strip,
    reenter_pword: params[:reenter_pword].strip }
end

def input_username_error(user_name)
  if @storage.load_user_credentials.keys.include?(user_name) &&
     session[:user_name] != user_name
    'That username already exists. Please choose a different username.'
  elsif user_name == ''
    'Username cannot be blank! Please enter a username.'
  end
end

def signup_pword_error(user_details)
  if user_details[:pword] != user_details[:reenter_pword] &&
     user_details[:pword] != ''
    'The passwords do not match.'
  elsif user_details[:pword] == ''
    'Password cannot be blank! Please enter a password.'
  end
end

def input_email_error(email)
  if email == ''
    'Email cannot be blank! Please enter an email.'
  elsif email !~ URI::MailTo::EMAIL_REGEXP
    'That is not a valid email address.'
  elsif email_list.include?(email) &&
        session[:user_email] != email
    'That email address already exists.'
  end
end

def signup_input_error(user_details)
  error = []
  error << input_username_error(user_details[:user_name])
  error << signup_pword_error(user_details)
  error << input_email_error(user_details[:email])
  error.delete(nil)
  error.empty? ? '' : error.join(' ')
end

def edit_pword_error(pword, reenter_pword)
  return unless pword != reenter_pword && pword != ''
  'The passwords do not match.'
end

def credentials_error(current_pword)
  return unless !valid_credentials?(session[:user_name], current_pword)
  'That is not the correct current password. Try again!'
end

def no_change_error(user_details, current_pword)
  return unless
    session[:user_name] == user_details[:user_name] &&
    (current_pword == user_details[:pword] || user_details[:pword] == '') &&
    session[:user_email] == user_details[:email]
  'You have not changed any of your details.'
end

def edit_login_error(user_details, current_pword)
  error = []
  error << input_username_error(user_details[:user_name])
  error << edit_pword_error(user_details[:pword], user_details[:reenter_pword])
  error << input_email_error(user_details[:email])
  error << credentials_error(current_pword)
  error << no_change_error(user_details, current_pword)
  error.delete(nil)
  error.empty? ? '' : error.join(' ')
end

def details_changed(new_user_details)
  changes = []
  changes << 'username' if session[:user_name] != new_user_details[:user_name]
  changes << 'password' if new_user_details[:pword] != ''
  changes << 'email' if session[:user_email] != new_user_details[:email]
  changes.empty? ? 'none' : changes.join(', ')
end

def change_username(new_user_name)
  @storage.change_username(session[:user_name], new_user_name)
  session[:user_name] = new_user_name
end

def change_pword(new_pword)
  @storage.change_pword(session[:user_name], new_pword)
end

def change_email(new_email)
  @storage.change_email(session[:user_name], new_email)
  session[:user_email] = new_email
end

def update_user_credentials(new_user_details)
  changed_details = details_changed(new_user_details)

  change_username(new_user_details[:user_name]) if
    changed_details.include?('username')

  change_pword(new_user_details[:pword]) if
    changed_details.include?('password')

  change_email(new_user_details[:email]) if
    changed_details.include?('email')

  session[:message] = "The following have been updated: #{changed_details}."
end

def not_integer?(num)
  !(num.floor - num).zero?
end

def match_locked_down?(match)
  match_date_time = "#{match[:match_date]} #{match[:kick_off]}"
  (Time.now + LOCKDOWN_BUFFER) > Time.parse(match_date_time)
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

def set_criteria_to_default
  { match_status: 'all',
    prediction_status: 'all',
    tournament_stages: ['Group Stages', 'Round of 16', 'Quarter Finals', 
      'Semi Finals', 'Third Fourth Place Play-off', 'Final'] }
end

def calculate_lockdown
  lockdown_timedate = Time.now + LOCKDOWN_BUFFER
  lockdown_date = lockdown_timedate.strftime("%Y-%m-%d")
  lockdown_time = lockdown_timedate.strftime("%k:%M:%S")
  {date: lockdown_date, time: lockdown_time}
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
  @match = @storage.load_single_match(match_id)
  @match[:locked_down] = match_locked_down?(@match)
  session[:message] = 'Match locked down!' if @match[:locked_down]
  erb :match_details
end

post '/match/add_prediction' do
  require_signed_in_user
  match_id = params[:match_id].to_i
  @match = @storage.load_single_match(match_id)
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
  home_points = params[:home_team_points].to_f
  away_points = params[:away_team_points].to_f
  match_id = params[:match_id].to_i
  @match = @storage.load_single_match(match_id)
  session[:message] = match_result_error(@match, home_points, away_points)
  if session[:message]
    status 422
    erb :match_details
  else
    @storage.add_result(
      match_id, home_points.to_i, away_points.to_i, session[:user_id]
    )
    session[:message] = 'Result submitted.'
    redirect "/match/#{match_id}"
  end
end

get '/matches/all' do
  require_signed_in_user
  session[:criteria] = set_criteria_to_default()
  @matches = @storage.load_all_matches
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
  session[:criteria] = extract_search_criteria(params)
  lockdown = calculate_lockdown
  @matches = @storage.filter_matches(session[:user_id], session[:criteria], lockdown)
  erb :matches_list do
    erb :match_filter_form
  end
end

not_found do
  redirect '/'
end
