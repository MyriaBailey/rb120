module Boxable
  MAX_WIDTH = 60

  def display_big_box(text, width = MAX_WIDTH)
    puts big_box(text, width)
  end

  def display_two_boxes(text_1, text_2, total_width = MAX_WIDTH)
    separator = '  '
    individual_width = (total_width - separator.length) / 2

    texts = [text_1, text_2]
    texts.map! { |text| force_array(text) }
    
    line_difference = (texts[0].size - texts[1].size).abs
    texts.min_by(&:size).concat([' '] * line_difference)

    box_1 = big_box(texts[0], individual_width)
    box_2 = big_box(texts[1], individual_width)

    merged = box_1.zip(box_2)
    merged.map! { |line| line.join(separator) }
    puts merged
  end

  def thick_linebreak(width = MAX_WIDTH)
    puts '=' * width
  end

  private

  def force_array(text)
    [text].flatten
  end

  def big_box(text, width = MAX_WIDTH)
    lines = force_array(text)
    formatted_lines = lines.map { |line| sq_center_text(line, width) }
    
    box = [
            sq_equals_bar(width),
            sq_space_bar(width),
            formatted_lines,
            sq_space_bar(width),
            sq_equals_bar(width)
  ].flatten
  end

  def sq_equals_bar(width)
    '[]' + '=' * (width - 4) + '[]'
  end

  def sq_space_bar(width)
    '||' + ' ' * (width - 4) + '||'
  end

  def sq_center_text(text, width)
    '|| ' + text.center(width - 6) + ' ||'
  end
end

module Displayable
  def screenwipe
    system 'clear'
  end

  def empty_line
    puts ""
  end

  def linebreak
    puts "--------------------------------"
  end

  def say(text)
    puts "  " + text
  end

  def list(text)
    say(" — " + text)
  end

  def join_and(items)
    if    items.size == 1 then items.first.to_s
    elsif items.size == 2 then items.join(' and ')
    else  items[0...-1].join(', ') + ', and ' + items.last.to_s
    end
  end

  def plural_s(count)
    count == 1 ? '' : 's'
  end

  def apostrophe_s(name)
    name.end_with?('s') ? name + "'" : name + "'s"
  end
end

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

  def devalue
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
  attr_reader :name, :hand, :points

  include Displayable

  def initialize(deck)
    @deck = deck
    @hand = []
    @points = 0
  end

  def turn
    name_turn

    until bust?
      return unless hit?
      hit
    end
    bust
  end

  def draw_card
    hand << deck.draw
    update_points
  end

  def bust?(points = @points)
    points > TwentyOne::BUST
  end

  private

  attr_reader :deck
  attr_writer :points, :hand, :name

  def name_turn
    puts "It's #{apostrophe_s(name)} turn."
  end
  
  def update_points
    total = hand.map(&:worth).sum

    while bust?(total)
      possible_ace_idx = hand.index do |card|
        card.ace? && card.worth == card.initial_worth
      end

      if possible_ace_idx
        hand[possible_ace_idx].devalue
        total = hand.map(&:worth).sum
      else
        break
      end
    end
    self.points = total
  end

  def bust
    puts "And that's a bust!"
  end
end

class Player < Participant
  def initialize(deck)
    super
    # @name = "Placeholder"
    prompt_name
  end

  def display_hand
    puts "#{name} has: " + join_and(hand)
  end

  private

  def prompt_name
    puts "Please enter your name to start:"
    name = ''

    loop do
      name = gets.strip
      break unless name.empty?
      puts "Please try again."
    end

    self.name = name
  end

  def small_linebreak
    puts ". . ."
  end

  def display_points
    puts "Your current points are: #{points}"
  end

  def hit?
    display_points
    puts "Hit or stay? (h/s)"
    answer = ''
    loop do
      answer = gets.chomp
      break if answer.start_with?('h') || answer.start_with?('s')
      puts "Not a valid response, try again."
    end
    answer.start_with?('h')
  end

  def hit
    draw_card
    small_linebreak
    puts "You drew the #{hand.last}!"
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

  def hit?
    points < 17
  end

  def hit
    draw_card
    puts "#{name} draws a card . . ."
  end
end

class TwentyOne
  include Displayable
  include Boxable

  BUST = 21

  def initialize
    welcome
    display_rules

    @deck = Deck.new
    @player = Player.new(deck)
    @dealer = Dealer.new(deck)
    @participants = [player, dealer]
  end

  def start
    screenwipe

    deal_cards
    display_header
    display_cards

    player.turn
    dealer.turn unless player.bust?

    determine_winner
    display_results
  end

  private

  attr_reader :player, :dealer, :participants
  attr_accessor :deck, :winner

  def welcome
    screenwipe
    display_big_box("Welcome to 21!")
    empty_line
  end

  def display_rules
    say "Here's how to play:"
    empty_line

    list "Each player is dealt two cards to start with."
    list "On your turn, you can either Hit or Stay."
    list "Each time you hit, you draw a card."
    list "You can hit as many times as you'd like, but!"
    list "Going over 21 is a bust and you're out!"
    list "Choose to stay put if you don't want to risk it!"
    list "The person closest to 21 without going over wins!"

    empty_line
    thick_linebreak
    empty_line
  end

  def display_header
    display_big_box("Round 1 - Player's Turn")
  end

  def deal_cards
    2.times { participants.each(&:draw_card) }
  end

  def display_cards
    info = participants.map do |p|
      divider = '-' * p.name.length
      if p.is_a?(Player)
        hand = p.hand.map(&:to_s)
        total = "Total: #{p.points} points"
      else
        hand = p.hand.map.with_index do |card, idx|
          idx == 0 ? card.to_s : "Unknown card"
        end
        total = "Total: Unknown"
      end

      [
        p.name,
        divider,
        hand,
        divider,
        total
      ].flatten
    end

    display_two_boxes(info.first, info.last)
    empty_line
  end

  def determine_winner
    remaining = participants.reject(&:bust?)
    self.winner = remaining.first
    return if remaining.one?

    self.winner = case player.points <=> dealer.points
                  when  1 then player
                  when -1 then dealer
                  when  0 then nil
                  end
  end

  def display_results
    participants.each do |p|
      puts "#{apostrophe_s(p.name)} hand:"
      puts "#{join_and(p.hand)}"
      puts "for a total of #{p.points} point#{plural_s(p.points)}."
    end

    if winner
      puts "#{winner.name} won!"
    else
      puts "It's a tie!"
    end
  end
end

TwentyOne.new.start