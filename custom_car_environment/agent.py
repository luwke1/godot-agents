from collections import defaultdict
import gymnasium as gym
import numpy as np
import xml.etree.ElementTree as ET


# a Q learning agent to run on the car racing environment
class customRacingAgent:
    def __init__(
            self,
            learning_rate: float,
            initial_epsilon: float,
            epsilon_decay: float,
            final_epsilon: float,
            discount_factor: float = 0.95,
    ):
        self.q_values = {}                              # initialize Q values policy for each of the 5 actions
        self.lr = learning_rate                         # learning rate for a single simulation
        self.discount_factor = discount_factor          # discount factor for computing Q value
        self.epsilon = initial_epsilon                  # starting epsilon (probability of choosing an action randomly)
        self.epsilon_decay = epsilon_decay              # the amount to decrease epsilon after each simulation
        self.final_epsilon = final_epsilon              # the smallest the epsilon can be
        self.training_error = []

    # used to get an action from the agent with probability 1-epsilon or a random action with probability epsilon
    def get_action(self, image) -> int:
        if image not in self.q_values.keys():
            self.q_values[image] = [0.0] * 5
        # with probability epsilon return a random action to explore the environment
        if np.random.random() < self.epsilon:
            return np.random.randint(0, 5)
        # with probability (1 - epsilon) use policy
        else:
            return self.q_values[image].index(max(self.q_values[image]))

    # update the Q-value of an action
    def update(self, image, action, reward, terminated, next_image):
        if image not in self.q_values.keys():
            self.q_values[image] = [0.0] * 5
        if next_image not in self.q_values.keys():
            self.q_values[next_image] = [0.0] * 5

        future_q_value = (not terminated) * np.max(self.q_values[next_image])
        temporal_difference = (
            reward + self.discount_factor * future_q_value - self.q_values[image][action]
        )

        self.q_values[image][action] = (
            self.q_values[image][action] + self.lr * temporal_difference
        )
        self.training_error.append(temporal_difference)

    # decreases epsilon by epsilon_decay
    def decay_epsilon(self):
        self.epsilon = max(self.final_epsilon, self.epsilon - self.epsilon_decay)

    # saves the
    def save_policy(self, filename):
        root = ET.Element("QValues")
        for state, q_values in self.q_values.items():
            state_elem = ET.SubElement(root, "State", key=str(state))
            for action, q_value in enumerate(q_values):
                action_elem = ET.SubElement(state_elem, "Action", id=str(action))
                action_elem.text = str(q_value)

        tree = ET.ElementTree(root)
        tree.write(filename)

    def load_policy(self, filename):
        tree = ET.parse(filename)
        root = tree.getroot()

        for state_elem in root.findall("State"):
            state_key = eval(state_elem.get("key"))
            q_values = []
            for action_elem in state_elem.findall("Action"):
                q_values.append(float(action_elem.text))

            self.q_values[state_key] = q_values
