from wrapper import Wrapper

import tkinter as tk
from tkinter import filedialog, messagebox
import webbrowser
import os

os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"


class EggDropMenu:
    def __init__(self, root):
        self.root = root
        self.root.title("Egg Drop Menu")
        self.wrapper = Wrapper()

        # Number of Episodes for Training
        tk.Label(root, text="Number of Steps for Training:").grid(row=0, column=0, sticky="w")
        self.episodes_entry = tk.Entry(root)
        self.episodes_entry.grid(row=0, column=1, padx=10, pady=5)

        # File to Load Policy
        tk.Label(root, text="Load Policy File:").grid(row=1, column=0, sticky="w")
        self.load_file_entry = tk.Entry(root, width=30)
        self.load_file_entry.grid(row=1, column=1, padx=10, pady=5)
        tk.Button(root, text="Browse", command=self.load_file_dialog).grid(row=1, column=2, padx=5)

        # Buttons for Play, Train Q Agent, and Test Q Agent
        tk.Button(root, text="Play Game", command=self.play_game).grid(row=3, column=0, padx=10, pady=10)
        tk.Button(root, text="Train Q Agent", command=self.train_model_Q).grid(row=3, column=1, padx=10, pady=10)
        tk.Button(root, text="Test Q Agent", command=self.test_model_Q).grid(row=3, column=2, padx=10, pady=10)

        # Buttons for Train PPO Agent and Test PPO Agent
        tk.Button(root, text="Train PPO Agent", command=self.train_model_ppo).grid(row=4, column=0, padx=10, pady=10)
        tk.Button(root, text="Test PPO Agent", command=self.test_model_ppo).grid(row=4, column=1, padx=10, pady=10)

        # How to Play Button
        tk.Button(root, text="How to Play", command=self.show_how_to_play).grid(row=5, column=0, padx=10, pady=10)

        # Documentation Button
        tk.Button(root, text="Documentation", command=self.open_documentation).grid(row=5, column=1, padx=10, pady=10)

        # Exit Button
        tk.Button(root, text="Exit", command=root.quit).grid(row=5, column=2, padx=10, pady=10)

    def load_file_dialog(self):
        filename = filedialog.askopenfilename(title="Select Load File", filetypes=[("Pickle Files", "*.pkl"), ("All Files", "*.*")])
        if filename:
            self.load_file_entry.delete(0, tk.END)
            self.load_file_entry.insert(0, filename)

    def play_game(self):
        ep_reward, num_steps = self.wrapper.playGame()
        text = f"""
        steps = {num_steps}
        reward = {ep_reward}
        """

        if ep_reward > 200:
            text += "Successful Landing!"
        else:
            text += "Your egg cracked"

        messagebox.showinfo("Results", text)

    # trains the Q learning model
    def train_model_Q(self):
        try:
            steps = int(self.episodes_entry.get())

            messagebox.showinfo("Train Q Agent", f"Training Q-Agent for {steps}")
            self.wrapper.trainModel_Q(steps)

        except ValueError:
            messagebox.showerror("Input Error", "Please enter a valid number for steps.")

    # calls the testModel function to run the trained model on one simulation
    def test_model_Q(self):
        load_file = self.load_file_entry.get()
        if not load_file:
            messagebox.showerror("Input Error", "Please specify a file to load the policy from.")
            return

        messagebox.showinfo("Test Q Agent", f"Testing Q-Agent with policy loaded from: {load_file}")
        try:
            ep_reward, num_steps = self.wrapper.testModel_Q(load_file)
            text = f"""
                    steps = {num_steps}
                    reward = {ep_reward}
                    """

            if ep_reward > 200:
                text += "Successful Landing!"
            else:
                text += "Your egg cracked"

            messagebox.showinfo("Results", text)
        except:
            messagebox.showerror("Error", "make sure you are loading a Q learning save file")

    # trains the PPO model
    def train_model_ppo(self):
        try:
            steps = int(self.episodes_entry.get())

            messagebox.showinfo("Train PPO Agent", f"Training PPO-Agent for {steps}")
            self.wrapper.trainModel_PPO(steps)

        except ValueError:
            messagebox.showerror("Input Error", "Please enter a valid number for steps.")

    # calls the testModel_PPO function to run the trained model on one simulation
    def test_model_ppo(self):
        load_file = self.load_file_entry.get()
        if not load_file:
            messagebox.showerror("Input Error", "Please specify a file to load the policy from.")
            return

        messagebox.showinfo("Test PPO Agent", f"Testing PPO-Agent with policy loaded from: {load_file}")
        try:
            ep_reward, num_steps = self.wrapper.testModel_PPO(load_file)
            text = f"""
                    steps = {num_steps}
                    reward = {ep_reward}
                    """

            if ep_reward > 200:
                text += "Successful Landing!"
            else:
                text += "Your egg cracked"

            messagebox.showinfo("Results", text)
        except:
            messagebox.showerror("Error", "make sure you are loading a PPO save file")

    def show_how_to_play(self):
        text = """
        To play the game:

        - Use the up arrow to move the egg up.
        - Use the left and right arrows to move in the corresponding direction.

        Points are earned by:
        - Moving close to the landing area.
        - Moving slowly.
        - Keeping the egg horizontal.
        - 10 points for each leg in contact with the ground.
        - 100 points for a safe landing.

        Penalties:
        - Moving away from the landing area.
        - Moving too fast.
        - Tilting the egg.
        - Using wind to move the egg sideways (-0.03).
        - Using the wind to move the egg up (-0.3).
        - -100 for crashing.

        Landings above 200 points are considered successful.
        
        - After training an agent, videos for some of the simulations will be stored in the videos folder
        - Graphs showing the agent's training over time will be stored in the plots folder
        """
        messagebox.showinfo("How to Play", text)

    def open_documentation(self):
        # Open the documentation link in the default web browser
        webbrowser.open("https://shorturl.at/l19pA")

# Initialize the Tkinter root and menu
root = tk.Tk()
menu = EggDropMenu(root)
root.mainloop()
