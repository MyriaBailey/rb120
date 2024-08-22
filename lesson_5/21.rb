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
  attr_reader :name

  def initialize
    @hand = []
  end

  def join_and(items)
    if    items.size == 1 then items.first.to_s
    elsif items.size == 2 then items.join(' and ')
    else  items[0...-1].join(', ') + ', and ' + item.last.to_s
    end
  end
end

class Player < Participant
  def initialize
    super
    @name = "Placeholder"
  end

  def show_hand
    puts "#{name} has: " + join_and(hand)
  end
end

class Dealer < Participant
  def initialize
    super
    @name = "Dealer"
  end
end

class Game
  def initialize
    welcome
    @deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
  end

  def start
    deal_cards
    show_cards
  end

  private

  attr_reader :player, :dealer
  attr_accessor :deck

  def welcome
    puts "Welcome to 21!"
  end

  def deal_cards
    [player, dealer].each do |participant|
      participant.hand << deck.draw
    end
  end

  def show_cards
    player.show_hand
  end
end

Game.new.start