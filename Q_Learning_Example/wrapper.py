# make sure these libraries are installed
import gymnasium as gym
import pygame
import os
import time
import matplotlib.pyplot as plt
import pandas as pd

# in Q_agent.py file
from Q_agent import Q_agent


class wrapper:
    def __init__(self, steps, learning_rate=2.5e-4, start_epsilon=1.0, final_epsilon=0.1):
        self.steps = steps
        self.gym_id = 'FrozenLake-v1'
        env = gym.make('FrozenLake-v1', desc=None, map_name="4x4", is_slippery=True, render_mode='rgb_array')

        epsilon_decay = start_epsilon / steps  # reduce the exploration over time
        self.agent = Q_agent(
            learning_rate=learning_rate,
            initial_epsilon=start_epsilon,
            epsilon_decay=epsilon_decay,
            final_epsilon=final_epsilon
        )

        exp_name = "Q_learning"
        self.seed = 1
        self.run_name = f"{self.gym_id}__{exp_name}__{self.seed}__{int(time.time())}"
        self.env = gym.wrappers.RecordVideo(env, f"videos/{self.run_name}")

    # trains the Q learning model to play the game
    def trainModel_Q(self):
        self.env.reset(seed=self.seed)

        total_steps = 0
        num_episodes = 0
        ep_rewards = []
        steps_per_ep = []
        epsilons = []
        while total_steps < self.steps:
            num_episodes += 1
            obs, info = self.env.reset()
            done = False
            episode_return = 0
            ep_steps = 0

            # play one episode
            while not done and ep_steps < 300:
                action = self.agent.get_action(obs)
                next_obs, reward, terminated, truncated, info = self.env.step(action)

                episode_return += reward

                # update the agent
                self.agent.update(obs, action, reward, terminated, next_obs)

                # update whether the environment is done and update the current obs
                done = terminated or truncated
                obs = next_obs

                total_steps += 1
                ep_steps += 1
                epsilon = self.agent.decay_epsilon()

                if total_steps % 100 == 0:
                    epsilons.append(epsilon)

            ep_rewards.append(episode_return)
            steps_per_ep.append(ep_steps)
            print(f"Total Steps {total_steps} | Episode Return {episode_return}")


        os.makedirs("agents", exist_ok=True)
        agent_dir = os.path.join("agents", self.run_name)

        self.agent.save_policy(agent_dir)
        self.save_plots(ep_rewards, steps_per_ep, epsilons)

        self.env.close()

    # saves plots in plots/run_name
    def save_plots(self, ep_rewards, steps_per_ep, epsilons):
        # make directory to store plots
        os.makedirs("plots", exist_ok=True)
        plot_dir = os.path.join("plots", self.run_name)
        os.makedirs(plot_dir, exist_ok=True)

        # Plot for Episode Rewards
        smoothed_rewards = pd.Series(ep_rewards).rolling(window=500, center=True).mean()

        plt.figure(figsize=(10, 6))
        plt.plot(ep_rewards, label="Episode Rewards", marker="o")
        plt.plot(smoothed_rewards, label="Smoothed rewards (Moving Average 500)", linestyle="--")
        plt.title("Episode Rewards Over Time")
        plt.xlabel("Episode")
        plt.ylabel("Reward")
        plt.legend()
        plt.grid()
        plt.savefig(os.path.join(plot_dir, "ep_rewards.png"), dpi=300)
        plt.clf()

        # Plot for Steps per Episode
        smoothed_steps = pd.Series(steps_per_ep).rolling(window=500, center=True).mean()

        plt.figure(figsize=(10, 6))
        plt.plot(steps_per_ep, label="Steps per Episode", marker="o")
        plt.plot(smoothed_steps, label="Smoothed Steps per Episode (Moving Average 500)", linestyle="--")
        plt.title("Steps per Episode Over Time")
        plt.xlabel("Episode")
        plt.ylabel("Steps")
        plt.legend()
        plt.grid()
        plt.savefig(os.path.join(plot_dir, "steps_per_ep.png"), dpi=300)
        plt.clf()

        # Plot for Epsilon
        plt.figure(figsize=(10, 6))
        plt.plot(epsilons, label="Epsilon", marker="o")
        plt.title("Epsilon Over Time")
        plt.xlabel("Step")
        plt.ylabel("Epsilon")
        plt.legend()
        plt.grid()
        plt.savefig(os.path.join(plot_dir, "epsilons.png"), dpi=300)
        plt.clf()

        print(f"Plots saved in the directory: {plot_dir}")
