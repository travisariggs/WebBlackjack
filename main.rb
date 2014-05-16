require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK = 21
DEALER_STAY_MIN = 17

BLACKJACK_WIN_FACTOR = 2  # Amount to increase winnings on Blackjack!

MINIMUM_BUY_IN = 200
MINIMUM_BET = 20

#@@@@@@@@@@@@@@ HELPERS @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
helpers do

  def calculate_hand(hand)
    # hand = An array of cards, which are arrays
    #  of [value, suit]. The value is a string
    #  of '1', '2', ..., 'J', 'Q', 'K', 'A'.
    #  The suit is 'C', 'D', 'H' or 'S'
    total = 0
    values = hand.map { |c| c[0] }
    values.each do |value|

      total += case value
        when 'A' then 11
        when 'K' then 10
        when 'Q' then 10
        when 'J' then 10
        else value.to_i
      end

    end

    # If it's a bust, can we convert any aces to 1's?
    if total > BLACKJACK
      values.select{ |c| c == 'A' }.length.times do 
        total -= 10
        break if total <= BLACKJACK
      end
    end

    total

  end

  def hand_status?(hand_total)

    if hand_total == BLACKJACK
      status = 'Blackjack'
    elsif hand_total > BLACKJACK
      status = 'Bust'
    else
      status = 'Playing'
    end

  end

  def show_card(card)
    # 'card' is an array of ['3', 'C']

    # Convert the suit from a capital letter to spelled out name
    suit = case card[1]
      when 'C' then 'clubs'
      when 'D' then 'diamonds'
      when 'H' then 'hearts'
      when 'S' then 'spades'
      else 'ERROR'
    end

    # Convert the value to the image name value needed
    value = case card[0]
      when 'A' then 'ace'
      when 'K' then 'king'
      when 'Q' then 'queen'
      when 'J' then 'jack'
      else card[0]
    end

    # Build the image tag
    tag = "<img src='/images/cards/#{suit}_#{value}.jpg' class='card' />"

  end

  def green_message(message)
    @success = message
  end

  def red_message(message)
    @error = message
  end

  def blue_message(message)
    @info = message
  end

  def winner!(message, factor=1)
    @show_hit_stay_buttons = false
    @show_play_again_quit_buttons = true  

    session[:money] += factor*session[:wager]

    green_message(message)
  end

  def loser!(message)
    @show_hit_stay_buttons = false
    @show_play_again_quit_buttons = true

    session[:money] -= session[:wager]

    red_message(message)

  end

  def tie!(message)
    @show_hit_stay_buttons = false
    @show_play_again_quit_buttons = true

    blue_message(message)
  end

end

#@@@@@@@@@@@@@@@@ ROUTES @@@@@@@@@@@@@@@@@@@@@@@@@@@@
before do
  @show_hit_stay_buttons = true
  @turn = 'Player'
end

get '/' do
  redirect '/welcome'
end

get '/welcome' do
  erb :welcome
end

post '/welcome' do
  if params[:username].empty?
    red_message("You have to tell me who you are...")
    halt erb(:welcome)
  elsif params[:money].empty?
    red_message("You can't play without some money")
    halt erb(:welcome)
  elsif params[:money].to_i < MINIMUM_BUY_IN
    red_message("I'm sorry.  There is a minimum buy-in of $#{MINIMUM_BUY_IN} for this table.")
    halt erb(:welcome)
  end

  session[:username] = params[:username]
  session[:money] = params[:money].to_i
  session[:starting_money] = params[:money].to_i
  # Progress to the game
  redirect '/bet'
end

get '/bet' do
  if !session[:username]
    redirect '/welcome'
  # Have any money left to play?
  elsif session[:money] < MINIMUM_BET
    redirect '/game/player/quit'
  else
    erb :bet
  end
end

post '/bet' do
  if params[:wager].empty?
    red_message("You need to place a bet")
    halt erb(:bet)
  elsif params[:wager].to_i < MINIMUM_BET
    red_message("I'm sorry.  There is a minimum wager of $#{MINIMUM_BET} for this table.")
    halt erb(:bet)
  elsif params[:wager].to_i > session[:money]
    red_message("You only have $#{session[:money]}.")
    halt erb(:bet)
  end

  session[:wager] = params[:wager].to_i
  redirect '/game'
end


get '/game' do
  # Do we have all the initial information to start a game?
  unless session[:username] && session[:money] && session[:wager]
    redirect '/welcome'

  else 
    #@@@@ Setup a new round
    # Setup Shoe of Cards
    suits = ['C', 'D', 'H', 'S']
    cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    session[:shoe] = cards.product(suits).shuffle

    # Deal Cards
    session[:dealer_hand] = []
    session[:player_hand] = []

    session[:dealer_hand] << session[:shoe].pop
    session[:player_hand] << session[:shoe].pop
    session[:dealer_hand] << session[:shoe].pop
    session[:player_hand] << session[:shoe].pop

    # Set status variable for 'PlayersTurn'
    session[:game_status] = 'PlayersTurn'

    # Check initial game status for Blackjack
    total = calculate_hand(session[:player_hand])
    status = hand_status?(total)

    # Anyone blackjack?
    if calculate_hand(session[:player_hand]) == BLACKJACK
      winner!("Blackjack, baby!", BLACKJACK_WIN_FACTOR)
    elsif calculate_hand(session[:dealer_hand]) == BLACKJACK
      loser!("Dealer has Blackjack")
    end

    erb :game 
  end
end

post '/game/player/hit' do
  session[:player_hand] << session[:shoe].pop

  total = calculate_hand(session[:player_hand])
  status = hand_status?(total)

  if status == 'Blackjack'
    winner!("Blackjack, baby!", BLACKJACK_WIN_FACTOR)
  elsif status == 'Bust'
    loser!("Sorry, #{session[:username]}, you busted")
  end

  erb :game
end

post '/game/player/stay' do
  @show_hit_stay_buttons = false
  @turn = 'Dealer'
  blue_message("#{session[:username]}, you have decided to stay.")
  redirect '/game/dealer'
end

get '/game/player/quit' do
  erb :close
end

post '/game/player/quit' do
  erb :close
end

post '/game/player/playagain' do
  redirect '/bet'
end

get '/game/dealer' do
  @show_hit_stay_buttons = false
  @turn = 'Dealer'

  dealer_total = calculate_hand(session[:dealer_hand])
  dealer_status = hand_status?(dealer_total)

  if dealer_status == 'Blackjack'
    loser!("Dealer has Blackjack")
  elsif dealer_status == 'Bust'
    winner!("Dealer busted!  #{session[:username]}, you win!")
  elsif dealer_total < DEALER_STAY_MIN
    @show_dealer_hit = true
  else # 17, 18, 19, 20

    # Dealer is done, see who won
    user_total = calculate_hand(session[:player_hand])

    if user_total > dealer_total
      winner!("#{session[:username]}, you won!")
    elsif user_total < dealer_total
      loser!("Sorry #{session[:username]}, you lost this time.")
    elsif user_total == dealer_total
      tie!("It's a push.")
    else
      red_message("SOMETHING WENT TERRIBLY WRONG!")
    end

  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_hand] << session[:shoe].pop
  redirect '/game/dealer'
end



