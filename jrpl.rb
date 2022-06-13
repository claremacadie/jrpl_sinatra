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

# Helper methods for view templates
helpers do
end

# Helper methods for routes
def setup_user_session_data(user_id)
  user_details = @storage.load_user_details(user_id)
  session[:user_id] = user_id
  session[:user_name] = user_details[:user_name]
  session[:user_email] = user_details[:email]
  session[:user_roles] = user_details[:roles]
end

def signin_with_cookie
  return false unless cookies[:series_id] && cookies[:token]
  user_id = @storage.user_id_from_cookies(cookies[:series_id], cookies[:token])
  return false unless user_id
  setup_user_session_data(user_id)
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
  set_series_id_cookie
  set_token_cookie
  @storage.save_cookie_data(session[:user_id], cookies[:series_id], cookies[:token])
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
    session[:user_name] = new_user_details[:user_name]
    session[:user_id] = @storage.user_id(new_user_details[:user_name])

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
  @users = @storage.load_users_details
  erb :administer_accounts
end

post '/users/toggle_admin' do
  require_signed_in_as_admin
  user_id = params[:user_id].to_i
  if params.keys.include?('admin') && !@storage.user_admin?(user_id)
    @storage.assign_admin(user_id)
  elsif !params.keys.include?('admin') && @storage.user_admin?(user_id)
    @storage.unassign_admin(user_id)
  end
  redirect '/users/administer_accounts'
end

not_found do
  redirect '/'
end
