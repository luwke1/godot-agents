import copy
import random

# this is the algorithm used to explore the board
# num_sims is the number of training simulations the algorithm will go through to develop its policy
# learning_rate changes the impact a single simulation has on the policy
# random_move_test is the chance that the algorithm will move randomly instead of following the policy during a test
#       This should be between 0 and 1
# random_move_train is the chance that the algorithm will move randomly instead of following the policy while training
#       This should be between 0 and 1
# revisit_policy is the amount that the algorithm will be motivated to avoid visited positions while using the policy
#       This amount is subtracted from the policy for moves to previously visited positions
#       The policy is not permanently modified by this only for the current move
# allowed_off_board determines whether the agent can move off the board or not
class monte_carlo_agent:
    def __init__(self, board, num_sims=10000, learning_rate=0.1, random_move_test=0, random_move_train=0.9, revisit_policy=15, allowed_off_board=True):
        self.board = board                                  # the board for the agent to travel on
        self.ROWS = len(board)                              # the number of rows in the board
        self.COLS = len(board[0])                           # the number of columns in the board
        self.num_sims = num_sims                            # the number of training simulations to run
        self.policy = {}                                    # the policy for the algorithm
        self.offMapPenalty = self.ROWS * self.COLS * -2     # the score penalty for going off the board
        self.learning_rate = learning_rate
        self.random_move_test = random_move_test
        self.random_move_train = random_move_train
        self.revisit_policy = revisit_policy
        self.allowed_off_board = allowed_off_board

        self.initializePolicy()
        self.train()
        self.test()

    # this function is used to train the agent by running simulations
    def train(self):
        for i in range(self.num_sims):                  # for each simulation
            x, y = self.ROWS // 2, self.COLS // 2       # set starting point
            path = []                                   # store position and weight for visited ((x, y), weight)
            simBoard = copy.deepcopy(self.board)        # copy board to avoid modifying the original
            visited = set()                             # store visited nodes for penalty

            for j in range(self.ROWS * self.COLS):                          # run agent for row * column moves
                if x >= self.ROWS or x < 0 or y >= self.COLS or y < 0:      # if it's off the board
                    path.append(((x, y), self.offMapPenalty))               # add position to path
                    break
                path.append(((x, y), simBoard[x][y]))                       # add position to path
                visited.add((x, y))                                         # add position to visited
                simBoard[x][y] = 0                                          # set position reward/penalty to 0

                x, y = self.move(x, y, self.random_move_train, visited)     # determine the next move

            self.updatePolicy(path)     # update policy based on path and reward/penalty

    # This function is used to test the agent on the board
    def test(self):
        score = 0                                   # set score
        x, y = self.ROWS // 2, self.COLS // 2       # set starting point
        path = []  # ((x, y), weight)               # store position and weight for visited ((x, y), weight)
        testBoard = copy.deepcopy(self.board)       # copy board to avoid modifying the original
        visited = set()                             # store visited nodes for penalty

        for j in range(self.ROWS * self.COLS):                          # run agent for row * column moves
            if x >= self.ROWS or x < 0 or y >= self.COLS or y < 0:      # if it's off the board
                path.append(((x, y), self.offMapPenalty))               # add position to path
                score += self.offMapPenalty                             # add off map penalty to the score
                break
            path.append(((x, y), testBoard[x][y]))                      # add position to path
            visited.add((x, y))                                         # add position to visited
            score += testBoard[x][y]                                    # add position reward/penalty to score
            testBoard[x][y] = 0                                         # set position reward/penalty to 0

            x, y = self.move(x, y, self.random_move_test, visited)      # determine the next move

        self.showResults(score, testBoard, path)    # display the results of the test

    # This function shows the results of a test (called in the test() function
    # score is the score of the algorithm during the test
    # testBoard is the copy of the board used during the test
    # path is the path taken by the algorithm as a list
    def showResults(self, score, testBoard, path):
        # print the original board
        print("\n\nOriginal board:")
        for row in range(self.ROWS):
            print(self.board[row])

        # print the board after test
        print("\n\nTest board (path is shown in zeros):")
        for row in range(self.ROWS):
            print(testBoard[row])

        # print the path taken by the algorithm
        print("\n\nThis is the path:\n")
        for position in path:
            print(position)

        # print the score
        print("\n\nScore of test:\t" + str(score))

    # This function determines and returns the next x and y values to move the agent
    # x is the current x position of the algorithm
    # y is the current y position of the algorithm
    # random_move is the chance the algorithm will move randomly (not according to policy)
    # visited is a set of visited positions on the board (for the revisit policy)
    def move(self, x, y, random_move, visited):
        direction = 'l'
        if random.random() < random_move:                           # if the move will be random
            if self.allowed_off_board:                              # if the agent can move off the board
                direction = random.choice(['l', 'r', 'u', 'd'])     # move randomly
            else:                                                   # otherwise move randomly on the board
                if x == self.ROWS - 1 and y == self.COLS - 1:
                    direction = random.choice(['l', 'u'])
                elif x == self.ROWS - 1 and y == 0:
                    direction = random.choice(['l', 'd'])
                elif x == 0 and y == self.COLS - 1:
                    direction = random.choice(['r', 'u'])
                elif x == 0 and y == 0:
                    direction = random.choice(['r', 'd'])
                elif x == self.ROWS - 1:
                    direction = random.choice(['l', 'u', 'd'])
                elif x == 0:
                    direction = random.choice(['r', 'u', 'd'])
                elif y == self.COLS - 1:
                    direction = random.choice(['l', 'r', 'u'])
                elif y == 0:
                    direction = random.choice(['l', 'r', 'd'])
        else:                                                       # if the movement wont be random
            state_policy = copy.deepcopy(self.policy[(x, y)])       # make a copy of the policy

            if not self.allowed_off_board:  # if the algorithm cant go off the board make the off board move the lowest
                if x == self.ROWS - 1:
                    state_policy['r'] = float('-inf')
                if x == 0:
                    state_policy['l'] = float('-inf')
                if y == self.COLS - 1:
                    state_policy['d'] = float('-inf')
                if y == 0:
                    state_policy['u'] = float('-inf')

            # modify the policy copy to make revisits to the same position less likely
            state_policy['l'] -= self.revisit_policy if (x - 1, y) in visited else 0
            state_policy['r'] -= self.revisit_policy if (x + 1, y) in visited else 0
            state_policy['u'] -= self.revisit_policy if (x, y - 1) in visited else 0
            state_policy['d'] -= self.revisit_policy if (x, y + 1) in visited else 0

            direction = max(state_policy, key=state_policy.get) # choose a direction based on the policy

        # modify x or y for the new position
        if direction == 'l':
            x -= 1
        elif direction == 'r':
            x += 1
        elif direction == 'u':
            y -= 1
        else:
            y += 1

        return x, y     # return new x and y

    # this function updates all moves in the policy taken in the path
    # path is the path the algorithm took during a simulation
    def updatePolicy(self, path):
        score = 0
        last = (-1, -2)
        while len(path) != 0:               # while the path is not empty
            position, weight = path.pop()   # pop the last move
            if last != (-1, -2):            # update the policy for the move by learning_rate * change
                if last[0] < position[0]:  # l
                    self.policy[position]['l'] += self.learning_rate * (score - self.policy[position]['l'])
                elif last[0] > position[0]:  # r
                    self.policy[position]['r'] += self.learning_rate * (score - self.policy[position]['r'])
                elif last[1] < position[1]:  # u
                    self.policy[position]['u'] += self.learning_rate * (score - self.policy[position]['u'])
                elif last[1] > position[1]:  # d
                    self.policy[position]['d'] += self.learning_rate * (score - self.policy[position]['d'])
            score += weight                 # add the positions weight to score
            last = position                 # update last position

    # this function initializes all parts of the policy to the number of rows in the board
    def initializePolicy(self):
        val = self.ROWS
        for row in range(self.ROWS):
            for col in range(self.COLS):
                self.policy[(row, col)] = {}
                self.policy[(row, col)]['u'] = val
                self.policy[(row, col)]['d'] = val
                self.policy[(row, col)]['l'] = val
                self.policy[(row, col)]['r'] = val

    # this function prints the policy
    def showPolicy(self):
        temp = self.policy.items()
        for spot in temp:
            print(spot)
