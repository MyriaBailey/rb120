class Move
  VALUES = ['rock', 'paper', 'scissors', 'lizard', 'spock']

  def self.convert(value)
    return value unless value.is_a?(String)

    case value
    when 'rock'     then Rock.new
    when 'paper'    then Paper.new
    when 'scissors' then Scissors.new
    when 'lizard'   then Lizard.new
    when 'spock'    then Spock.new
    end
  end

  def to_s
    self.class.to_s.downcase
  end

  def beats?(other_move)
    beatable_moves.include?(other_move.class)
  end
end

class Rock < Move
  def beatable_moves
    [Scissors, Lizard]
  end
end

class Paper < Move
  def beatable_moves
    [Rock, Spock]
  end
end

class Scissors < Move
  def beatable_moves
    [Paper, Lizard]
  end
end

class Lizard < Move
  def beatable_moves
    [Paper, Spock]
  end
end

class Spock < Move
  def beatable_moves
    [Rock, Scissors]
  end
end

class Player
  attr_accessor :score
  attr_reader :name, :move

  def initialize
    set_name
    self.score = 0
  end

  def make_move(value)
    self.move = Move.convert(value)
  end

  def beats?(other_player)
    move.beats?(other_player.move)
  end

  private

  attr_writer :name, :move
end

class Human < Player
  def set_name
    n = ''
    loop do
      puts "What's your name?"
      n = gets.chomp
      break unless n.empty?
      puts "Sorry, must enter a value"
    end
    self.name = n
  end

  def choose
    choice = nil
    loop do
      puts "Please choose one of the following:"
      puts Move::VALUES.join(', ')

      choice = gets.chomp.downcase
      break if Move::VALUES.include? choice
      puts "Sorry, invalid choice."
    end
    make_move(choice)
  end
end

class Computer < Player
  def initialize(h)
    super()
    @history = h
  end

  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end

  def choose(last_winner)
    move = case name
           when 'R2D2'     then always_rock
           when 'Hal'      then mostly_scissors
           when 'Sonny'    then most_recent_choice
           when 'Chappie'  then beats_most_recent
           when 'Number 5' then last_winning_choice(last_winner)
           else random_move
           end

    make_move(move)
  end

  private

  attr_reader :history

  def random_move
    move = Move::VALUES.sample
    Move.convert(move)
  end

  def always_rock
    Rock.new
  end

  def mostly_scissors
    move = ['scissors', 'scissors', 'scissors', 'rock'].sample
    Move.convert(move)
  end

  def most_recent_choice
    history.empty? ? random_move : history.last[:human]
  end

  def beats_most_recent
    move = most_recent_choice
    move.beatable_moves.sample.new
  end

  def last_winning_choice(winner)
    if history.empty?
      random_move
    elsif winner.nil?
      most_recent_choice
    elsif winner.is_a?(Human)
      history.last[:human]
    else
      history.last[:computer]
    end
  end
end

class RPSGame
  private

  WINNING_SCORE = 5

  attr_reader :human, :computer, :history
  attr_accessor :winner, :grand_winner

  def initialize
    @history = []
    @human = Human.new
    @computer = Computer.new(history)
  end

  def linebreak
    puts "-----------------------------------------"
  end

  def display_welcome_message
    puts "Welcome to Rock, Paper, Scissors!"
    puts "First to win #{WINNING_SCORE} matches wins the game!"
  end

  def display_goodbye_message
    puts "Thanks for playing Rock, Paper, Scissors. Good bye!"
  end

  def display_moves
    puts "#{human.name} chose #{human.move}."
    puts "#{computer.name} chose #{computer.move}."
  end

  def determine_winner
    self.winner = if human.beats?(computer)
                    human
                  elsif computer.beats?(human)
                    computer
                  end
  end

  def update_score
    winner.score += 1 if winner
  end

  def display_winner
    if winner.nil?
      puts "It's a tie!"
    else
      puts "#{winner.name} won!"
    end
  end

  def display_scores
    puts "#{human.name}'s score is: #{human.score}"
    puts "#{computer.name}'s score is: #{computer.score}"
  end

  def determine_grand_winner
    self.grand_winner = if human.score == WINNING_SCORE
                          human
                        elsif computer.score == WINNING_SCORE
                          computer
                        end
  end

  def display_grand_winner
    puts "#{grand_winner.name} won #{WINNING_SCORE} matches!"
    puts "#{grand_winner.name} wins the game!"
  end

  def display_history
    linebreak
    puts "Move history"
    history.each_with_index do |moves, idx|
      linebreak
      puts "Round #{idx + 1}:"
      puts "#{human.name} played #{moves[:human]}, #{computer.name} " \
           "played #{moves[:computer]}."
    end
  end

  def play_again?
    linebreak

    answer = nil

    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if ['y', 'n'].include?(answer)
      puts "Sorry, must be y or n."
    end

    answer == 'y'
  end

  def game_sequence
    linebreak
    human.choose
    computer.choose(winner)
    history << { human: human.move, computer: computer.move }
  end

  def winner_sequence
    linebreak
    display_moves

    determine_winner
    display_winner
  end

  def scoring_sequence
    linebreak
    update_score
    display_scores

    determine_grand_winner
    return unless grand_winner
    linebreak
    display_grand_winner
  end

  public

  def play
    linebreak
    display_welcome_message

    loop do
      game_sequence
      winner_sequence
      scoring_sequence

      break if grand_winner || play_again? == false
    end

    display_goodbye_message
    # display_history
  end
end

RPSGame.new.play
