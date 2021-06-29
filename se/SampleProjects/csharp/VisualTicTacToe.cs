using System; 
using System.Drawing; 
using System.Windows.Forms;

namespace SamplePrograms {

    /// <summary>
    /// Very simple two-player tic-tac-toe game using Windows.Forms.
    /// </summary>
    public class VisualTicTacToe : Form {

        /// <summary>
        /// Constructor
        /// </summary>
        public VisualTicTacToe() {
            createGameBoard();
        }

        /// <summary>
        /// Create the game board.
        /// </summary>
        private void createGameBoard() {
           BackColor = Color.Black;
           Text = "Tic Tac Toe";
           Size = new Size(300, 300);
           CenterToScreen();
           this.FormBorderStyle = FormBorderStyle.FixedDialog;
           this.MaximizeBox = false;
           this.MinimizeBox = false;
           this.MinimumSize = Size;
           this.MaximumSize = Size;
           this.MaximizeBox = false;
           this.SizeGripStyle = SizeGripStyle.Hide;
           this.ImeMode = ImeMode.NoControl;

           int tabIndex=1;
           for (int i=0; i<3; i++) {
               for (int j=0; j<3; j++) {
                   mGrid[i,j] = new Button();
                   mGrid[i,j].AutoSize = true;
                   mGrid[i,j].BackColor = Color.Gray;
                   mGrid[i,j].ForeColor = Color.DarkBlue;
                   mGrid[i,j].Location = new Point(10+90*i, 10+70*j);
                   mGrid[i,j].Name = "Row" + i + "_Column" + j;
                   mGrid[i,j].Size = new Size(80, 60);
                   mGrid[i,j].TabIndex = tabIndex++;
                   mGrid[i,j].Text = "-";
                   mGrid[i,j].Font = new Font("Microsoft Sans Serif", 32F, FontStyle.Regular, GraphicsUnit.Point, ((byte)(0)));
                   mGrid[i,j].Click += new EventHandler(buttonClick);
                   this.Controls.Add(mGrid[i,j]);
               }
           }

           mTurnSignal = new Label();
           mTurnSignal.AutoSize = true;
           mTurnSignal.ForeColor = Color.White;
           mTurnSignal.Location = new Point(10, 230);
           mTurnSignal.Name = "Turn";
           mTurnSignal.Size = new Size(280, 40);
           mTurnSignal.TabIndex = tabIndex++;
           mTurnSignal.Font = new Font("Microsoft Sans Serif", 16F, FontStyle.Bold, GraphicsUnit.Point, ((byte)(0)));
           mTurnSignal.Text = "Player X goes first";
           this.Controls.Add(mTurnSignal);


        }

        /// <summary>
        /// Handle a button click which maps to one player taking a turn.
        /// </summary>
        /// <param name="sender">button this event is coming from</param>
        /// <param name="e">event arguments (unsued)</param>
        private void buttonClick(object sender, EventArgs e) {
            // place an X or O on the board, and disable this button
            Button b = (Button)sender;
            mNumTurnsTaken++;
            if (mNumTurnsTaken % 2 == 0) {
                b.Text = "O";
                mTurnSignal.Text = "Player X: your turn";
            } else {
                b.Text = "X";
                mTurnSignal.Text = "Player O: your turn";
            }
            b.Enabled = false;

            // check if we have a winner
            var winnerName = checkForWinner();
            if (winnerName == "Draw") {
                mTurnSignal.Text = winnerName;
                MessageBox.Show("Game Ended in a Draw.");
                resetGameBoard(winnerName);
            } else if (winnerName != "") {
                mTurnSignal.Text = "Player " + winnerName + " Wins!";
                MessageBox.Show(mTurnSignal.Text);
                resetGameBoard(winnerName);
            }
        }

        /// <summary>
        /// Reset the game board.  The previous winner has to start second.
        /// If the game ends in a draw, then the previous player who started
        /// has to start second.
        /// </summary>
        /// <param name="winnerName">X, O, or Draw</param>
        private void resetGameBoard(string winnerName) {
            foreach (Button b in mGrid) {
                b.Enabled = true;
                b.Text = "-";
            }
            if (winnerName == "X") {
                mNumTurnsTaken = 1;
            } else if (winnerName == "O") {
                mNumTurnsTaken = 0;
            }
            if (mNumTurnsTaken % 2 == 0) {
                mTurnSignal.Text = "Player X goes first";
            } else {
                mTurnSignal.Text = "Player O goes first";
            }
        }

        /// <summary>
        /// Simplifies checking who has marked this item on the board.
        /// </summary>
        /// <param name="r">row</param>
        /// <param name="c">column</param>
        /// <returns>"X", "O", or "-"</returns>
        private string ownedBy(int r, int c) {
            string who = mGrid[r,c].Text;
            return who;
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
            Application.Run(new VisualTicTacToe());
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
        Button[,] mGrid = {{null,null,null}, {null,null,null}, {null,null,null}};

        /// <summary>
        /// Label indicating whose turn it is next.
        /// </summary>
        Label mTurnSignal = null;
    }
}


