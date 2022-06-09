require 'bcrypt'
require 'pry'
require 'sinatra'
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
def user_signed_in?
  session.key?(:user_name)
end

def require_signed_in_user
  return if user_signed_in?

  session[:message] = 'You must be signed in to do that.'
  redirect '/'
end

def require_signed_out_user
  return unless user_signed_in?

  session[:message] = 'You must be signed out to do that.'
  redirect '/'
end

def valid_credentials?(user_name, pword)
  credentials = @storage.load_user_credentials
  if credentials.key?(user_name)
    bcrypt_pword = BCrypt::Password.new(credentials[user_name])
    bcrypt_pword == pword
  else
    false
  end
end

def signup_username_error(user_name)
  if user_name == 'admin'
    "Username cannot be 'admin'! Please choose a different username."
  elsif @storage.load_user_credentials.keys.include?(user_name)
    'That username already exists. Please choose a different username.'
  elsif user_name == ''
    'Username cannot be blank! Please enter a username.'
  end
end

def signup_pword_error(pword, reenter_pword)
  if pword != reenter_pword && pword != ''
    'The passwords do not match.'
  elsif pword == ''
    'Password cannot be blank! Please enter a password.'
  end
end

def signup_email_error(email)
  # elsif @storage.load_user_email_addresses.include?(email)
  #   'That email address already exists.'
  if email == ''
    'Email cannot be blank! Please enter an email.'
  end
end

def signup_input_error(user_details)
  error = []
  error << signup_username_error(user_details[:user_name])
  error << signup_pword_error(user_details[:pword], user_details[:reenter_pword])
  error << signup_email_error(user_details[:email])
  error.delete(nil)
  error.empty? ? '' : error.join(' ')
end

def extract_user_details(params)
  { user_name: params[:new_user_name].strip,
    email: params[:new_email].strip,
    pword: params[:new_pword].strip,
    reenter_pword: params[:reenter_pword].strip }
end

def edit_username_error(user_name)
  if user_name == 'admin' && session[:user_name] != 'admin'
    "Username cannot be 'admin'! Please choose a different username."
  elsif session[:user_name] == 'admin' && user_name != 'admin'
    'Admin cannot change their username.'
  elsif @storage.load_user_credentials.keys.include?(user_name) && session[:user_name] != user_name
    'That username already exists. Please choose a different username.'
  elsif user_name == ''
    'Username cannot be blank! Please enter a username.'
  end
end

def edit_pword_error(pword, reenter_pword)
  return unless pword != reenter_pword && pword != ''
  
  'The passwords do not match.'
 end

def edit_email_error(email)
  # elsif @storage.load_user_email_addresses.include?(email)
  #   'That email address already exists.'
  # remember to use session[:user_email]
  if email == ''
    'Email cannot be blank! Please enter an email.'
  end
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
  error << edit_username_error(user_details[:user_name])
  error << edit_pword_error(user_details[:pword], user_details[:reenter_pword])
  error << edit_email_error(user_details[:email])
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

def update_user_credentials(new_user_details)
  changed_details = details_changed(new_user_details)
  if changed_details.include?('username')
    @storage.change_username(session[:user_name], new_user_details[:user_name])
    session[:user_name] = new_user_details[:user_name]
  end
  if changed_details.include?('password')
    @storage.change_pword(session[:user_name], new_user_details[:pword])
  end
  if changed_details.include?('email')
    @storage.change_email(session[:user_name], new_user_details[:email])
    session[:user_email] = new_user_details[:email]
  end
  session[:message] = "The following have been updated: #{changed_details}."
end

# Routes
get "/" do
  erb :home
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  session[:intended_route] = params['intended_route']
  params[:user_name]
  user_name = params[:user_name].strip
  pword = params[:pword].strip
  if valid_credentials?(user_name, pword)
    session[:user_name] = user_name
    session[:user_id] = @storage.user_id(user_name)
    session[:user_email] = @storage.user_email(user_name)
    session[:message] = 'Welcome!'
    redirect(session[:intended_route])
  else
    session[:message] = 'Invalid credentials.'
    status 422
    erb :signin
  end
end

post '/users/signout' do
  session.delete(:user_name)
  session.delete(:user_id)
  session.delete(:user_email)
  session[:message] = 'You have been signed out.'
  redirect '/'
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
  unless session[:message].empty?
    status 422
    erb :signup
  else
    @storage.upload_new_user_credentials(new_user_details)
    session[:user_name] = new_user_details[:user_name]
    session[:user_id] = @storage.user_id(new_user_details[:user_name])
    session[:message] = 'Your account has been created.'
    redirect(session[:intended_route])
  end
end

get '/user/edit_credentials' do
  require_signed_in_user
  erb :edit_credentials
end

post '/user/edit_credentials' do
  require_signed_in_user
  current_pword = params[:current_pword].strip
  new_user_details = extract_user_details(params)
  session[:message] = edit_login_error(new_user_details, current_pword)
  unless session[:message].empty?
    status 422
    erb :edit_credentials
  else
    update_user_credentials(new_user_details)
    redirect '/'
  end
end

get '/all_users_list' do
  @users = @storage.all_users_list
  session[:message] = 'This is a list of the display names of all users.'
  erb :all_users_list
end

not_found do
  redirect "/"
end
