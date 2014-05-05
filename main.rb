require 'rubygems'
require 'sinatra'

set :sessions, true


get '/' do
  redirect '/welcome'
end

get '/welcome' do
  erb :welcome
end

post '/bet' do
  erb :bet
end

post '/game' do
  erb :game
end

# get '/game' do
#   erb :game
# end


