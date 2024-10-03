import copy
import random

class monte_carlo_agent:
    def __init__(self, board, simulations):
        self.board = board
        self.ROWS = len(board)
        self.COLS = len(board[0])
        self.simulations = simulations
        self.policy = {}

        self.initializePolicy()
        self.train()
        self.test()

    def train(self):
        for i in range(self.simulations):
            score = 0
            x, y = self.ROWS // 2, self.COLS // 2
            path = []  # ((x, y), weight)
            simBoard = copy.deepcopy(self.board)

            for j in range(self.ROWS * self.COLS):
                if x >= self.ROWS or x < 0 or y >= self.COLS or y < 0:
                    path.append(((x, y), -1 * self.ROWS * self.COLS))
                    break
                path.append(((x, y), simBoard[x][y]))
                score += simBoard[x][y]
                simBoard[x][y] = 0

                direction = random.randint(0, 3)
                if direction == 0:
                    x -= 1
                elif direction == 1:
                    x += 1
                elif direction == 2:
                    y -= 1
                elif direction == 3:
                    y += 1

            self.updatePolicy(path)

    def test(self):
        score = 0
        x, y = self.ROWS // 2, self.COLS // 2
        path = []  # ((x, y), weight)
        testBoard = copy.deepcopy(self.board)

        for j in range(self.ROWS * self.COLS):
            if x >= self.ROWS or x < 0 or y >= self.COLS or y < 0:
                path.append(((x, y), -1 * self.ROWS * self.COLS))
                break
            path.append(((x, y), testBoard[x][y]))
            score += testBoard[x][y]
            testBoard[x][y] = 0
            x, y = self.move(x, y)

        self.showResults(score, testBoard, path)

    def showResults(self, score, testBoard, path):
        print("\n\nOriginal board:\n")
        for row in range(self.ROWS):
            print(self.board[row])

        print("\n\nTest board (path is shown in zeros):\n")
        for row in range(self.ROWS):
            print(testBoard[row])

        print("\n\nThis is the path:\n")
        print(path)

        print("\n\nScore of test:\t" + str(score))

    def move(self, x, y):
        weights = self.policy[(x, y)].items()
        weights = [(x, y) for (y, x) in weights]
        weights.sort(reverse=True)
        direction = weights[0][1]

        if direction == 'l':
            x -= 1
        elif direction == 'r':
            x += 1
        elif direction == 'u':
            y -= 1
        else:
            y += 1

        return x, y

    def updatePolicy(self, path):

        score = 0
        last = (-1, -2)
        while len(path) != 0:
            position, weight = path.pop()
            if last != (-1, -2):
                if last[0] < position[0]:  # l
                    self.policy[position]['l'] += score
                    self.policy[position]['l'] /= 2
                elif last[0] > position[0]:  # r
                    self.policy[position]['r'] += score
                    self.policy[position]['r'] /= 2
                elif last[1] < position[1]:  # u
                    self.policy[position]['u'] += score
                    self.policy[position]['u'] /= 2
                elif last[1] > position[1]:  # d
                    self.policy[position]['d'] += score
                    self.policy[position]['d'] /= 2
            score += weight
            last = position

    def initializePolicy(self):
        val = self.ROWS
        for row in range(self.ROWS):
            for col in range(self.COLS):
                self.policy[(row, col)] = {}
                self.policy[(row, col)]['u'] = val
                self.policy[(row, col)]['d'] = val
                self.policy[(row, col)]['l'] = val
                self.policy[(row, col)]['r'] = val

    def showPolicy(self):
        temp = self.policy.items()
        for spot in temp:
            print(spot)
