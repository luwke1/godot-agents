from board import *
from monte_carlo_agent import *

gameBoard = board(penalty=4)                                                    # make game board
newBoard = gameBoard.getBoard()                                                 # get a copy of the board
agent = monte_carlo_agent(newBoard, num_sims=40000, allowed_off_board=False)    # run the algorithm on the board
agent.showPolicy()                                                              # print the agent's policy
