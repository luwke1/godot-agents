from board import *
from monte_carlo_agent import *

gameBoard = board()
gameBoard.showBoard()
newBoard = gameBoard.getBoard()
agent = monte_carlo_agent(newBoard, 50000)
agent.showPolicy()