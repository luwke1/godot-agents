import custom_carRacing
import gymnasium as gym
import numpy as np
import pygame
from agent import customRacingAgent
from tqdm import tqdm
from PIL import Image

# a wrapper class for the game
# includes functions for training and testing the agent as well as playing the game
class Wrapper:
    def __init__(self):
        # map discrete actions to continuous actions
        self.discrete_actions = {
            0: np.array([0.0, 0.0, 0.0]),  # No action
            1: np.array([0.0, 1.0, 0.0]),  # Accelerate
            2: np.array([0.0, 0.0, 1.0]),  # Brake
            3: np.array([-1.0, 0.0, 0.0]),  # Steer left
            4: np.array([1.0, 0.0, 0.0])  # Steer right
        }

    # allows the user to play the game without the agent
    # the up arrow is gas
    # the down arrow is brake
    # the left arrow turns left
    # the right arrow turns right
    def playGame(self):
        env = gym.make(
            "CustomCarRacing-V0",
            render_mode="human",
            lap_complete_percent=0.95,
            domain_randomize=False,
        )

        observation, info = env.reset()

        episode_over = False
        while not episode_over:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    episode_over = True

                # Initialize action to no action by default
            action = self.discrete_actions[0]

            keys = pygame.key.get_pressed()  # Get the state of all keyboard keys

            # Map keys to actions
            if keys[pygame.K_UP]:  # Accelerate
                action = self.discrete_actions[1]
            elif keys[pygame.K_DOWN]:  # Brake
                action = self.discrete_actions[2]
            elif keys[pygame.K_LEFT]:  # Steer left
                action = self.discrete_actions[3]
            elif keys[pygame.K_RIGHT]:  # Steer right
                action = self.discrete_actions[4]

            # Take a step in the environment
            observation, reward, terminated, truncated, info = env.step(action)

            episode_over = terminated

        env.close()

    # trains the model on the environment
    # save_file is the name of the file the agent's policy will be saved to
    # load_file is the name of the file the starting policy will be loaded from
    # learning_rate influences how much a weight will change from one move (lower learning rate means less influence)
    # n_episodes is the number of simulations that will be run during training
    # start_epsilon is the percentage that the agent will choose a random move instead of based on policy at the
    #   beginning of the training
    # final_epsilon is the lowest amount that epsilon can be (percent change the agent will move randomly)
    def trainModel(self, save_file, load_file=None, learning_rate=0.01, n_episodes=1000, start_epsilon=1.0, final_epsilon=0.1):
        epsilon_decay = start_epsilon / (n_episodes / 2)  # reduce the exploration over time

        env = gym.make(
            "CustomCarRacing-V0",
            render_mode=None,
            lap_complete_percent=0.95,
            domain_randomize=False,
        )

        agent = customRacingAgent(
            learning_rate=learning_rate,
            initial_epsilon=start_epsilon,
            epsilon_decay=epsilon_decay,
            final_epsilon=final_epsilon
        )

        if load_file is not None:
            agent.load_policy(load_file)

        env = gym.wrappers.RecordEpisodeStatistics(env, buffer_length=n_episodes)

        for episode in tqdm(range(n_episodes)):
            obs, info = env.reset()
            done = False

            # play one episode
            while not done:
                obs = self.transform_image(obs)
                image = obs.tobytes()
                action = agent.get_action(image)
                next_obs, reward, terminated, truncated, info = env.step(self.discrete_actions[action])

                next_obs = self.transform_image(next_obs)
                next_image = next_obs.tobytes()

                # update the agent
                agent.update(image, action, reward, terminated, next_image)

                # update if the environment is done and the current obs
                done = terminated or truncated
                obs = next_obs

            agent.decay_epsilon()
            env.close()

        agent.save_policy(save_file)

    # tests the trained model on the environment and displays its actions on the environment
    # file_name is the name of the file to load the agent's policy from
    def testModel(self, file_name):
        learning_rate = 0.01
        n_episodes = 1
        start_epsilon = 0
        epsilon_decay = 0
        final_epsilon = 0

        env = gym.make(
            "CustomCarRacing-V0",
            render_mode="human",
            lap_complete_percent=0.95,
            domain_randomize=False,
        )

        agent = customRacingAgent(
            learning_rate=learning_rate,
            initial_epsilon=start_epsilon,
            epsilon_decay=epsilon_decay,
            final_epsilon=final_epsilon
        )

        agent.load_policy(file_name)

        obs, info = env.reset()
        done = False

        # play one episode
        while not done:
            obs = self.transform_image(obs)
            image = obs.tobytes()
            action = agent.get_action(image)
            next_obs, reward, terminated, truncated, info = env.step(self.discrete_actions[action])

            # update if the environment is done and the current obs
            done = terminated
            obs = next_obs

        agent.decay_epsilon()
        env.close()

    # transforms the image into a 16x16 to reduce states
    def transform_image(self, image_array):
        pil_image = Image.fromarray(image_array)
        return np.array(pil_image.resize((16, 16)))
