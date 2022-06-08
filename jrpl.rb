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

get '/all_users_list' do
  @users = @storage.all_users_list
  session[:message] = 'This is a list of the display names of all users.'
  erb :all_users_list
end
helpers do
end

get "/" do
  erb :home
end

not_found do
  redirect "/"
end
