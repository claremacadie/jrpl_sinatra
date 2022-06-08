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
  unless user_signed_in?
    session[:message] = 'You must be signed in to do that.'
    redirect '/'
  end
end

def require_signed_out_user
  if user_signed_in?
    session[:message] = 'You must be signed out to do that.'
    redirect '/'
  end
end

def valid_credentials?(username, password)
  credentials = @storage.load_user_credentials
  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

# rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength, Layout/LineLength
def signup_input_error(user_details)
  if user_details[:username] == '' && user_details[:new_password] == ''
    'Username and password cannot be blank! Please enter a username and password.'
  elsif user_details[:username] == ''
    'Username cannot be blank! Please enter a username.'
  elsif user_details[:username] == 'admin'
    "Username cannot be 'admin'! Please choose a different username."
  elsif @storage.load_user_credentials.keys.include?(user_details[:username])
    'That username already exists.'
  elsif user_details[:password] != user_details[:reenter_password]
    'The passwords do not match.'
  elsif user_details[:password] == ''
    'Password cannot be blank! Please enter a password.'
  end
end

def extract_user_details(params)
  {first_name: params[:new_firstname].strip,
  last_name: params[:new_lastname].strip,
  display_name: params[:new_displayname].strip,
  user_name: params[:new_username].strip,
  password: params[:new_password].strip,
  reenter_password: params[:reenter_password].strip}
end

# rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength, Layout/LineLength
def edit_login_error(user_details, current_password)
  if user_details[:username] == ''
    'New username cannot be blank! Please enter a username.'
  elsif user_details[:username] == 'admin'
    "New username cannot be 'admin'! Please choose a different username."
  elsif @storage.load_user_credentials.keys.include?(user_details[:username]) && session[:user_name] != user_details[:username]
    'That username already exists. Please choose a different username.'
  elsif !valid_credentials?(session[:user_name], current_password)
    'That is not the correct current password. Try again!'
  elsif user_details[:password] != user_details[:reenter_password]
    'The passwords do not match.'
  end
end
# rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength, Layout/LineLength

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Layout/LineLength
def update_user_credentials(user_details)
  @storage.change_user_details(session[:user_name], user_details)
  session[:user_name] = user_details[:user_name]
  session[:message] = 'Your account has been updated.'
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Layout/LineLength

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
  password = params[:password].strip
  if valid_credentials?(user_name, password)
    session[:user_name] = user_name
    session[:user_id] = @storage.user_id(user_name)
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
  # rubocop:disable Style/ParenthesesAroundCondition
  if (session[:message] =
        signup_input_error(new_user_details)
     )
    # rubocop:enable Style/ParenthesesAroundCondition
    status 422
    erb :signup
  else
    @storage.upload_new_user_credentials(new_user_details)
    session[:user_name] = new_user_details[:user_name]
    session[:user_id] = @storage.user_id(new_user_details[:email])
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
  current_password = params[:current_password].strip
  new_user_details = extract_user_details(params)

  # rubocop:disable Style/ParenthesesAroundCondition
  if (session[:message] =
        edit_login_error(new_user_details, current_password)
     )
    # rubocop:enable Style/ParenthesesAroundCondition
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
