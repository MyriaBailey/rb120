module Boxable
  MAX_WIDTH = 60

  def display_box(text)
    puts box(text, MAX_WIDTH)
  end

  def display_two_boxes(text1, text2)
    separator = '  '
    individual_width = (MAX_WIDTH - separator.length) / 2

    texts = equalize_texts(text1, text2)

    box1 = box(texts[0], individual_width)
    box2 = box(texts[1], individual_width)

    paired_box_lines = box1.zip(box2)
    paired_box_lines.map! { |line| line.join(separator) }
    puts paired_box_lines
  end

  def thick_linebreak(width = MAX_WIDTH)
    puts '=' * width
  end

  private

  def equalize_texts(text1, text2)
    texts = [text1, text2]
    texts.map! { |text| force_array(text) }

    line_difference = (texts[0].size - texts[1].size).abs
    texts.min_by(&:size).concat([' '] * line_difference)

    texts
  end

  def force_array(text)
    [text].flatten
  end

  def box(text, width = MAX_WIDTH)
    lines = force_array(text)
    formatted_lines = lines.map { |line| sq_center_text(line, width) }

    box = [
      sq_equals_bar(width),
      sq_space_bar(width),
      formatted_lines,
      sq_space_bar(width),
      sq_equals_bar(width)
    ]
    box.flatten
  end

  def sq_equals_bar(width)
    "[]#{'=' * (width - 4)}[]"
  end

  def sq_space_bar(width)
    "||#{' ' * (width - 4)}||"
  end

  def sq_center_text(text, width)
    "|| #{text.center(width - 6)} ||"
  end
end

module Displayable
  def screenwipe
    system 'clear'
  end

  def empty_line
    puts ""
  end

  def say(text)
    puts "  #{text}"
  end

  def list(text)
    say(" — #{text}")
  end

  def prompt(text)
    say(text)
  end

  def join_and(items)
    if    items.size == 1 then items.first.to_s
    elsif items.size == 2 then items.join(' and ')
    else
      "#{items[0...-1].join(', ')}, and #{items.last}"
    end
  end

  def plural_s(count)
    count == 1 ? '' : 's'
  end

  def apostrophe_s(name)
    name.end_with?('s') ? "#{name}'" : "#{name}'s"
  end
end

class Deck
  SUITS = %w(Hearts Diamonds Clubs Spades)
  VALUES = ('2'..'9').to_a + %w(Jack Queen King Ace)

  def initialize
    @cards = new_deck.shuffle
  end

  def reshuffle
    initialize
  end

  def draw
    cards.pop
  end

  private

  attr_reader :cards

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
    else
      value.to_i
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
  attr_reader :name, :hand, :points, :score

  include Displayable

  def initialize(deck)
    @deck = deck
    @hand = []
    @points = 0
    @score = 0
  end

  def to_s
    name
  end

  def draw_card
    hand << deck.draw
    update_points
  end

  def bust?(points = @points)
    points > TwentyOne::BUST
  end

  def stay?
    say "It's #{apostrophe_s(name)} turn."
    sleep 1.25
    !(hit?)
  end

  def hit(hit_text)
    say hit_text
    sleep 1.5
    draw_card
  end

  def bust
    say "And that's a bust!"
    sleep 1.75
  end

  def empty_hand
    self.hand = []
    self.points = 0
  end

  def update_score
    self.score += 1
  end

  private

  attr_reader :deck
  attr_writer :points, :hand, :name, :score

  def update_points
    total = hand.map(&:worth).sum

    while bust?(total)
      possible_ace_idx = hand.index do |card|
        card.ace? && card.worth == card.initial_worth
      end

      break unless possible_ace_idx
      hand[possible_ace_idx].devalue
      total = hand.map(&:worth).sum
    end
    self.points = total
  end
end

class Player < Participant
  def initialize(deck)
    super
    prompt_name
  end

  def hit
    super "Drawing a card..."
  end

  private

  def prompt_name
    prompt "Please enter your name to start:"
    name = ''

    loop do
      name = gets.strip
      break unless name.empty?
      prompt "Please try again."
    end

    self.name = name
  end

  def hit?
    prompt "Hit or stay? (h/s)"
    answer = ''

    loop do
      answer = gets.chomp
      break if answer.start_with?('h') || answer.start_with?('s')
      prompt "Not a valid response, try again."
    end
    answer.start_with?('h')
  end
end

class Dealer < Participant
  DEALER_STAYS = 17

  attr_accessor :reveal_cards

  def initialize(deck)
    super
    @name = "Dealer"
    @reveal_cards = false
  end

  def hit?
    points < DEALER_STAYS
  end

  def hit
    super "#{name} draws a card..."
  end
end

class TwentyOne
  include Displayable
  include Boxable

  BUST = 21
  GRAND_SCORE = 5

  def initialize
    welcome
    display_rules

    @deck = Deck.new
    @player = Player.new(deck)
    @dealer = Dealer.new(deck)
    @participants = [player, dealer]

    @round_num = 1
  end

  def start
    loop do
      play_game
      end_game

      break if grand_winner?
      break unless play_again?

      prep_new_game
    end
    goodbye
    cash_prize
  end

  protected

  def play_game
    deal_cards
    turn_loop(player)
    reveal_dealer_cards
    turn_loop(dealer) unless player.bust?
  end

  def turn_loop(participant)
    loop do
      refresh_ui

      break if participant.bust?
      return if participant.stay?
      participant.hit
    end
    participant.bust
  end

  def end_game
    determine_winner
    update_scores
    display_results
  end

  def prep_new_game
    reshuffle_cards
    update_round
  end

  private

  attr_reader :player, :dealer, :participants
  attr_accessor :deck, :winner, :grand_winner, :round_num

  def welcome
    screenwipe
    display_box("Welcome to #{BUST}!")
    empty_line
  end

  def display_rules
    say "Here's how to play:"
    empty_line

    rules_list.each { |rule| list(rule) }

    empty_line
    thick_linebreak
    empty_line
  end

  def rules_list
    [
      "Each player is dealt two cards to start with.",
      "On your turn, you can either Hit or Stay.",
      "Each time you hit, you draw a card.",
      "You can hit as many times as you'd like, but!",
      "Going over #{BUST} is a bust and you're out!",
      "Choose to stay put if you don't want to risk it!",
      "The person closest to #{BUST} without going over wins!"
    ]
  end

  def refresh_ui
    screenwipe
    display_header
    display_cards
  end

  def display_header
    scores = "#{player.score} - #{dealer.score}"
    text = "Round #{round_num} — Score: #{scores}"

    empty_line
    puts text.center(MAX_WIDTH)
    empty_line
  end

  def deal_cards
    2.times { participants.each(&:draw_card) }
  end

  def display_cards
    box_texts = participants.map { |p| hand_info(p) }

    display_two_boxes(box_texts.first, box_texts.last)
    empty_line
  end

  def hand_info(p)
    if p.is_a?(Player) || p.reveal_cards
      hand = p.hand.map(&:to_s)
      total = "Total: #{p.points} points"
    else
      hand = p.hand.map.with_index do |card, idx|
        idx == 0 ? card.to_s : "Unknown card"
      end
      total = "Total: Unknown"
    end

    organize_hand_info(p.name, hand, total)
  end

  def organize_hand_info(name, hand, total)
    divider = '-' * name.length

    [
      name,
      divider,
      hand,
      divider,
      total
    ].flatten
  end

  def reveal_dealer_cards
    dealer.reveal_cards = true
  end

  def determine_winner
    remaining = participants.reject(&:bust?)
    self.winner = remaining.first
    return if remaining.one?

    self.winner = case player.points <=> dealer.points
                  when 1  then player
                  when -1 then dealer
                  when 0  then nil
                  end
  end

  def update_scores
    winner&.update_score
  end

  def display_results
    refresh_ui
    text = "#{winner} won! "

    if winner == player
      say text + ["Congratulations!", "Great going!"].sample
    elsif winner == dealer
      say text + ["Better luck next time.", "Too bad."].sample
    else
      say "It's a tie! You're evenly matched!"
    end
  end

  def reshuffle_cards
    deck.reshuffle
    participants.each(&:empty_hand)
    dealer.reveal_cards = false
  end

  def update_round
    self.round_num += 1
  end

  def grand_winner?
    winner_idx = participants.index { |p| p.score >= GRAND_SCORE }
    return false if winner_idx.nil?
    self.grand_winner = participants[winner_idx]

    say "Looks like #{grand_winner} won #{GRAND_SCORE} rounds!"
    true
  end

  def play_again?
    prompt "Play again? (y/n)"
    answer = ''
    loop do
      answer = gets.chomp
      break if answer.start_with?('y') || answer.start_with?('n')
      prompt "Not a valid response, try again."
    end
    answer.start_with?('y')
  end

  def goodbye
    if grand_winner.is_a?(Player)
      say "Congratulations! You're a pro!"
    elsif grand_winner.is_a?(Dealer)
      say "Too bad, try again some other time."
    else
      say "See you next time!"
    end
  end

  def cash_prize
    cash = (player.score - dealer.score) * 100

    if cash > 0
      say "[You won $#{cash}!]"
    elsif cash < 0
      say "[You lost $#{cash.abs}...]"
    end
  end
end

TwentyOne.new.start
