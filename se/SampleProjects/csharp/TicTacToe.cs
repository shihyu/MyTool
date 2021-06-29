using System; 

namespace SamplePrograms {

    /// <summary>
    /// Very simple two-player tic-tac-toe game using System.Console.
    /// </summary>
    public class TicTacToe {

        /// <summary>
        /// Constructor
        /// </summary>
        public TicTacToe() {
        }

        /// <summary>
        /// Create the game board.
        /// </summary>
        private void writeGameBoard() {
            Console.Clear();
            Console.WriteLine("");
            Console.WriteLine("=========================");
            for (int i=0; i<3; i++) {
                Console.WriteLine("|       |       |       |");
                Console.WriteLine("|   " + ownedBy(i,0) + "   |   " + ownedBy(i,1) + "   |   " + ownedBy(i,2) + "   |");
                Console.WriteLine("|       |       |       |");
                Console.WriteLine("-------------------------");
            }
        }

        /// <summary>
        /// Play one turn
        /// </summary>
        private bool nextTurn() {

            if (mNumTurnsTaken % 2 == 0) {
                Console.WriteLine("Player X: your turn");
            } else {
                Console.WriteLine("Player O: your turn");
            }
            int r=0;
            int c=0;
            do {
                Console.Write("Enter: [top|center|bottom]-[left|center|right]  ");
                string response = Console.ReadLine();
                if (response == "top-left" || response == "tl") {
                    r = 0;
                    c = 0;
                } else if (response == "center-left" || response == "cl") {
                    r = 1;
                    c = 0;
                } else if (response == "bottom-left" || response == "bl") {
                    r = 2;
                    c = 0;
                } else if (response == "top-center" || response == "tc") {
                    r = 0;
                    c = 1;
                } else if (response == "center-center" || response=="center") {
                    r = 1;
                    c = 1;
                } else if (response == "bottom-center" || response == "bc") {
                    r = 2;
                    c = 1;
                } else if (response == "top-right" || response == "tr") {
                    r = 0;
                    c = 2;
                } else if (response == "center-right" || response == "cr") {
                    r = 1;
                    c = 2;
                } else if (response == "bottom-right" || response == "br") {
                    r = 2;
                    c = 2;
                } else if (response == "quit" || response=="bye" || response == "exit") {
                    return false;
                } else {
                    Console.WriteLine("Invalid input!");
                    continue;
                }
                if (ownedBy(r,c) != "-") {
                    Console.WriteLine("The " + response + "position is already taken!");
                    continue;
                }
            } while (false);

            // place an X or O on the board, and disable this button
            mNumTurnsTaken++;
            if (mNumTurnsTaken % 2 == 0) {
                mGrid[r,c] = 1;  // > 0 means player X
            } else {
                mGrid[r,c] = -1; // < 0 means player O
            }

            // successful turn
            return true;
        }

        /// <summary>
        /// Simplifies checking who has marked this item on the board.
        /// </summary>
        /// <param name="r">row</param>
        /// <param name="c">column</param>
        /// <returns>"X", "O", or "-"</returns>
        private string ownedBy(int r, int c) {
            var who = mGrid[r,c];
            if (who > 0) return "O";
            if (who < 0) return "X";
            return "-";
        }

        /// Checking that any player has won or not
        /// <summary>
        /// Check if either player has won the game, or if we have a draw.
        /// </summary>
        /// <returns>"X", "O", "Draw", or "" (no winner)</returns>
        private string checkForWinner() {

            for (int i=0; i<3; i++) {
                // winning condition for a row
                if (ownedBy(i,0) != "-") {
                    if (ownedBy(i,0) == ownedBy(i,1) && ownedBy(i,1) == ownedBy(i,2)) {
                        return ownedBy(i,0);
                    }
                }
                // winning condition for a column
                if (ownedBy(0,i) != "-") {
                    if (ownedBy(0,i) == ownedBy(1,i) && ownedBy(1,i) == ownedBy(2,i)) {
                        return ownedBy(0,i);
                    }
                }
            }

            // diagonal winning conditions
            if (ownedBy(1,1) != "-") {
                if (ownedBy(0,0) == ownedBy(1,1) && ownedBy(1,1) == ownedBy(2,2)) {
                    return ownedBy(0,0);
                } else if (ownedBy(2,0) == ownedBy(1,1) && ownedBy(1,1) == ownedBy(0,2)) {
                    return ownedBy(0,0);
                }
            }

            // check for a draw
            for (int i=0; i<3; i++) {
                for (int j=0; j<3; j++) {
                    if (ownedBy(i,j) == "-") {
                        return "";
                    }
                }
            }
            return "Draw";
        }


        /// <summary>
        /// The fun starts here
        /// </summary>
        static public void Main()
        {
            var game = new TicTacToe();

            while (true) {

                // show the game board
                game.writeGameBoard();

                // play one turn
                if (!game.nextTurn()) {
                    break;;
                }

                // check if we have a winner
                var winnerName = game.checkForWinner();
                if (winnerName == "Draw") {
                    Console.WriteLine("Game Ended in a Draw.");
                    break;
                } else if (winnerName != "") {
                    Console.WriteLine("Player " + winnerName + " Wins!");
                    break;
                }
            }
        }

        /// <summary>
        /// Keep track of the number of turns taken.
        /// When even: the next turn belongs to player X
        /// When odd:  the next turn belongs to player X
        /// </summary>
        int mNumTurnsTaken = 0;

        /// <summary>
        /// Tic-tac-toe box grid, 3x3 array of buttons.
        /// </summary>
        int[,] mGrid = {{0,0,0}, {0,0,0}, {0,0,0}};

    }
}

