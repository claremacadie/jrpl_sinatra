require 'pry'
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

helpers do
end

get "/" do
  erb :home
end

not_found do
  redirect "/"
end