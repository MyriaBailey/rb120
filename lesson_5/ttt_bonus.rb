require "pry"

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # cols
                  [[1, 5, 9], [3, 5, 7]]              # diagonals

  def initialize
    @squares = {}
    reset
  end

  def draw
    empty_line = "     |     |"
    divider    = "-----+-----+-----"
    rows = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    lines = rows.map do |row|
      [empty_line, draw_line(row), empty_line].join("\n")
    end

    puts lines.join("\n#{divider}\n")
  end

  def draw_line(row)
    markers = row.map { |n| square_at(n) }

    "  #{markers[0]}  |  #{markers[1]}  |  #{markers[2]}"
  end

  def square_at(key)
    @squares[key]
  end

  def []=(key, marker)
    @squares[key].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      line_squares = line.map { |key| square_at(key) }
      next if line_squares.any?(&:unmarked?)

      marker = line_squares.first.marker
      return marker if line_squares.all? { |sq| sq.marker == marker }
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end
end

class Square
  INITIAL_MARKER = " "

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end
end

class Player
  attr_reader :marker, :name

  def initialize(marker)
    @marker = marker
  end

  private

  attr_writer :marker, :name
end

class Person < Player
  def initialize
    prompt_name
    prompt_marker
  end

  def prompt_name
    puts "What is your name?"
    answer = ''
    loop do
      answer = gets.strip
      break unless answer.empty?
      puts "Please input a name."
    end
    self.name = answer.capitalize
  end

  def prompt_marker
    puts "What marker do you want to play as?"
      answer = ''
    loop do
      answer = gets.strip
      break unless answer.empty? || answer.size > 1
      puts "Sorry, not a valid marker."
    end
    self.marker = answer
  end

  def pick_move(board)
    
  end
end

module Displayable
  def clear
    system 'clear'
  end

  def display(text)
    # clear # (header?)
    puts text
    puts ""
  end

  def welcome
    display "Welcome to Tic Tac Toe!"
  end

  def goodbye
    display "Thanks for playing Tic Tac Toe! Goodbye!"
  end

  def list_players(players)
    list = players.map { |player| "#{player.name} is #{player.marker}" }
    list = list.join_or(list, "and") + '.'
    display list
  end

  # private

  def join_or(options, word='or')
    case options.size
    when 1
      options.first.to_S
    when 2
      options.join(" #{word} ")
    else
      options[0...-1].join(', ') + ", #{word} " + options.last.to_s
    end
  end
end

class TTTGame
  include Displayable

  private

  HUMAN_MARKER = "X"
  COMPUTER_MARKER = "O"

  attr_reader :board, :human, :computer, :players

  def initialize
    @board = Board.new
    @human = Person.new
    @computer = Player.new(COMPUTER_MARKER)
    @players = [human, computer]
  end

  def display_board
    puts "You're a #{human.marker}. Computer is a #{computer.marker}"
    puts ""
    board.draw
    puts ""
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def pick_square(player)
    player.marker == human.marker ? human_moves : computer_moves
  end

  def human_moves
    puts "Choose a square (#{join_or(board.unmarked_keys)}): "
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  def computer_moves
    board[(board.unmarked_keys.sample)] = computer.marker
  end

  def display_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      puts "You won!"
    when computer.marker
      puts "Computer won!"
    else
      puts "It's a tie!"
    end
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      puts "Sorry, must be y or n"
    end

    answer == 'y'
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end

  def reset
    board.reset
    clear
  end

  def game_sequence
    display_board

    players.cycle do |current_player|
      pick_square(current_player)
      break if board.someone_won? || board.full?
      clear_screen_and_display_board
    end

    display_result
  end

  public

  def play
    clear
    welcome

    loop do
      game_sequence
      break unless play_again?
      reset
      display_play_again_message
    end

    goodbye
  end
end

game = TTTGame.new
game.play
