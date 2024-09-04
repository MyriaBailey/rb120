class Deck
  SUITS = %w(Hearts Diamonds Clubs Spades)
  VALUES = ('2'..'9').to_a + %w(Jack Queen King Ace)

  attr_reader :cards

  def initialize
    reshuffle
  end

  def reshuffle
    self.cards = new_deck.shuffle
  end

  def draw
    cards.pop
  end

  private

  attr_writer :cards

  def new_deck
    new_deck = []
    Deck::SUITS.each do |suit|
      Deck::VALUES.each do |value|
        new_deck << Card.new(suit, value)
      end
    end
    new_deck
  end
end

class Card
  attr_reader :suit, :value, :name, :worth

  def initialize(s, v)
    @suit = s
    @value = v
    
    @name = "#{value} of #{suit}"
    @worth = initial_worth
  end

  def to_s
    name
  end

  def initial_worth
    if face_card? then 10
    elsif ace?    then 11
    else value.to_i
    end
  end

  def devalue_ace
    self.worth = 1 if ace?
  end

  def face_card?
    %w(Jack Queen King).include?(value)
  end

  def ace?
    value == "Ace"
  end

  private

  attr_writer :worth
end

class Participant
  attr_accessor :hand
  attr_reader :name, :deck

  def initialize(deck)
    @deck = deck
    @hand = []
  end

  def join_and(items)
    if    items.size == 1 then items.first.to_s
    elsif items.size == 2 then items.join(' and ')
    else  items[0...-1].join(', ') + ', and ' + item.last.to_s
    end
  end

  # FLESH OUT TURN SPECIFICS (EXACT ORDER, PROMPTS, ETC)
  # More importantly though: finish calculating points/busted and such
  def turn
    # until busted?
    #   return unless hit?
    #   draw_card
    # end
    # bust
  end

  def points
    total = hand.map(&:worth).sum
    if bust? # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      # !!! make bust? check @points, whereas this is the reader for it?
      # nono rename this to update score or something, with points separate
  end

  def draw_card
    hand << deck.draw
  end
end

class Player < Participant
  def initialize(deck)
    super
    @name = "Placeholder"
  end

  def display_hand
    puts "#{name} has: " + join_and(hand)
  end

  def hit?
    puts "Hit or stay? (h/s)"
    answer = ''
    loop do
      answer = gets.chomp
      break if answer.start_with?('h') || answer.start_with?('s')
      puts "Not a valid response, try again."
    end
    answer.start_with?('h')
  end
end

class Dealer < Participant
  def initialize(deck)
    super
    @name = "Dealer"
  end

  def display_hand
    puts "#{name} has: #{hand.first} and an unknown card."
  end
end

class Game
  def initialize
    welcome
    @deck = Deck.new
    @player = Player.new(deck)
    @dealer = Dealer.new(deck)
    @participants = [player, dealer]
  end

  def start
    deal_cards
    show_cards
    player.turn

    # TESTING:
    @player.points

    # HANDS TENTATIVELY MADE... WORK ON GAME LOOP
  end

  private

  attr_reader :player, :dealer, :participants
  attr_accessor :deck

  def screenwipe
    system 'clear'
  end

  def linebreak
    puts "--------------------------------"
  end

  def welcome
    screenwipe
    puts "Welcome to 21!"
    linebreak
  end

  def deal_cards
    2.times { participants.each(&:draw_card) }
  end

  def show_cards
    participants.each(&:display_hand)
  end
end

Game.new.start