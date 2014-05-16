require 'rubygems'
require 'sinatra'

set :sessions, true

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
    if total > 21
      values.select{ |c| c == 'A' }.length.times do 
        total -= 10
        break if total <= 21
      end
    end

    total

  end

  def hand_status?(hand_total)

    if hand_total == 21
      status = 'Blackjack'
    elsif hand_total > 21
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
  session[:username] = params[:username]
  session[:money] = params[:money].to_i
  session[:starting_money] = params[:money].to_i
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
  session[:wager] = params[:wager].to_i
  redirect '/game'
end


get '/game' do
  # Do we have all the initial information to start a game?
  unless session[:username] && session[:money] && session[:wager]
    redirect '/welcome'
  end

  # Have we already started playing?
  # if session[:shoe] && session[:dealer_hand] && session[:player_hand]
  #   erb :game

  # else 

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

  # Player blackjack?
  if calculate_hand(session[:player_hand]) == 21

    @success = "Blackjack, baby!"

    session[:money] += 2*session[:wager]

    @show_hit_stay_buttons = false
    @show_play_again_quit_buttons = true

  elsif calculate_hand(session[:dealer_hand]) == 21

    @error = "Dealer has Blackjack"

    session[:money] -= session[:wager]

    @show_hit_stay_buttons = false
    @show_play_again_quit_buttons = true

  end

  erb :game 
  
  #end

end

post '/game/player/hit' do
  session[:player_hand] << session[:shoe].pop

  total = calculate_hand(session[:player_hand])
  status = hand_status?(total)

  if status == 'Blackjack'

    @success = "Blackjack, baby!"

    session[:money] += 2*session[:wager]

    @show_hit_stay_buttons = false
    @show_play_again_quit_buttons = true

  elsif status == 'Bust'

    @error = "Sorry, #{session[:username]}, you busted"

    session[:money] -= session[:wager]

    @show_hit_stay_buttons = false
    @show_play_again_quit_buttons = true

  end

  erb :game
end

post '/game/player/stay' do
  @show_hit_stay_buttons = false
  @info = "#{session[:username]}, you have decided to stay."
  @turn = 'Dealer'
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

    @error = "Dealer has Blackjack"

    @show_play_again_quit_buttons = true

  elsif dealer_status == 'Bust'

    @success = "Dealer busted!  #{session[:username]}, you win!"

    @show_play_again_quit_buttons = true

  elsif dealer_total < 17

    @show_dealer_hit = true

  else # 17, 18, 19, 20

    # Dealer is done, see who won
    user_total = calculate_hand(session[:player_hand])

    if user_total > dealer_total
      @success = "#{session[:username]}, you won!"
      session[:money] += session[:wager]
    elsif user_total < dealer_total
      @error = "Sorry #{session[:username]}, you lost this time."
      session[:money] -= session[:wager]
    elsif user_total == dealer_total
      @info = "It's a push."
    else
      @error = "SOMETHING WENT TERRIBLY WRONG!"
    end

    @show_play_again_quit_buttons = true

    # Make decisions about the next round
    if session[:money] == 0
      redirect '/game/player/quit'
    end

  end

  erb :game

end

post '/game/dealer/hit' do

  @show_hit_stay_buttons = false
  @turn = 'Dealer'

  session[:dealer_hand] << session[:shoe].pop

  dealer_total = calculate_hand(session[:dealer_hand])
  dealer_status = hand_status?(dealer_total)

  if dealer_status == 'Blackjack'

    @error = "Dealer has Blackjack"

    session[:money] -= session[:wager]

    @show_play_again_quit_buttons = true

  elsif dealer_status == 'Bust'

    @success = "Dealer busted!  #{session[:username]}, you win!"

    session[:money] += session[:wager]

    @show_play_again_quit_buttons = true

  elsif dealer_total < 17

    @show_dealer_hit = true

  elsif [17, 18, 19, 20].include?(dealer_total)

    # Dealer is done, see who won
    user_total = calculate_hand(session[:player_hand])

    if user_total > dealer_total
      @success = "#{session[:username]}, you won!"
      session[:money] += session[:wager]
    elsif user_total < dealer_total
      @error = "Sorry #{session[:username]}, you lost this time."
      session[:money] -= session[:wager]
    elsif user_total == dealer_total
      @info = "It's a push."
    else
      @error = "SOMETHING WENT TERRIBLY WRONG!"
    end

    @show_play_again_quit_buttons = true

    # Make decisions about the next round
    if session[:money] == 0
      redirect '/game/player/quit'
    end

  end

  erb :game

end

# post '/game' do
#   # Setup initial game values

#   # Render the template
#   erb :game
# end

# get '/game' do
#   erb :game
# end


