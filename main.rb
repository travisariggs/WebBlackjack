require 'rubygems'
require 'sinatra'

set :sessions, true


get '/' do
  if session[:username]
    redirect '/bet'
  else
    redirect '/welcome'
  end
end

get '/welcome' do
  erb :welcome
end

post '/welcome' do
  session[:username] = params[:username]
  session[:money] = params[:money]
  # Progress to the game
  redirect '/bet'
end

get '/bet' do
  if session[:username]
    erb :bet
  else
    redirect '/welcome'
  end
end

post '/bet' do
  session[:wager] = params[:wager]
  redirect '/game'
end


get '/game' do
  # Do we have all the initial information to start a game?
  unless session[:username] && session[:money] && session[:wager]
    redirect '/welcome'
  end

  # Have we already started playing?
  if session[:shoe] && session[:dealer_hand] && session[:player_hand]
    erb :game
    
  else # Setup a new round
    # Setup Shoe of Cards
    suits = ['C', 'D', 'H', 'S']
    cards = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    session[:shoe] = cards.product(suits).shuffle

    # Deal Cards
    session[:dealer_hand] = []
    session[:player_hand] = []

    session[:dealer_hand] << session[:shoe].pop
    session[:player_hand] << session[:shoe].pop
    session[:dealer_hand] << session[:shoe].pop
    session[:player_hand] << session[:shoe].pop

    erb :game
  end
end

# post '/game' do
#   # Setup initial game values

#   # Render the template
#   erb :game
# end

# get '/game' do
#   erb :game
# end


