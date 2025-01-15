import random

# this class is used to make a board for the agent to explore
# size will change the board size (5x5 is default)
# bonus will change the number of bonuses on the board (4 is default)
# penalty will change the number of penalties on the board (2 is default)
class board:
    def __init__(self, size=5, bonus=4, penalty=2):
        self.size = size
        self.bonus = bonus
        self.penalty = penalty
        self.start = (self.size // 2, self.size // 2)
        self.board = []

        self.makeBoard()

    # make a board with the specified size, number of bonuses, and number of penalties
    def makeBoard(self):
        # initialize the board with -1 in each spot
        for i in range(self.size):
            self.board.append([-1] * self.size)

        # add bonuses to the board
        for j in range(self.bonus):
            x, y = self.getSpace()
            self.board[x][y] = self.size * self.size

        # add penalties to the board
        for k in range(self.penalty):
            x, y = self.getSpace()
            self.board[x][y] = -1 * self.size * self.size

    # this function returns a space that is not the starting space or occupied by a bonus or penalty
    def getSpace(self):
        x, y = self.start[0], self.start[1]  # set x and y to the agent starting point
        count = 0  # set the counter to 0

        # while the location is not acceptable try again
        while (x == self.start[0] and y == self.start[0]) or self.board[x][y] != -1:

            # generate coordinates
            x = random.randint(0, self.size - 1)
            y = random.randint(0, self.size - 1)
            count += 1

            # if a location has been generated 100 times without success throw an exception
            if count >= 100:
                raise Exception(
                    "Couldn't place bonus or penalty. Please retry with smaller number of penalties or bonuses"
                )

        return x, y  # return the acceptable coordinates

    # prints the board
    def showBoard(self):
        for i in range(len(self.board)):
            print(self.board[i])

    # returns a copy of the board
    def getBoard(self):
        return self.board.copy()
