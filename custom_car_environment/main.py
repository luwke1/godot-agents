from wrapper import Wrapper

import tkinter as tk
from tkinter import filedialog, messagebox

class CustomCarRacingMenu:
    def __init__(self, root):
        self.root = root
        self.root.title("Custom Car Racing Menu")
        self.wrapper = Wrapper()

        # Number of Episodes for Training
        tk.Label(root, text="Number of Episodes for Training:").grid(row=0, column=0, sticky="w")
        self.episodes_entry = tk.Entry(root)
        self.episodes_entry.grid(row=0, column=1, padx=10, pady=5)

        # File to Load Policy
        tk.Label(root, text="Load Policy File:").grid(row=1, column=0, sticky="w")
        self.load_file_entry = tk.Entry(root, width=30)
        self.load_file_entry.grid(row=1, column=1, padx=10, pady=5)
        tk.Button(root, text="Browse", command=self.load_file_dialog).grid(row=1, column=2, padx=5)

        # Save File for Policy after Training
        tk.Label(root, text="Save Policy File:").grid(row=2, column=0, sticky="w")
        self.save_file_entry = tk.Entry(root, width=30)
        self.save_file_entry.grid(row=2, column=1, padx=10, pady=5)
        tk.Button(root, text="Browse", command=self.save_file_dialog).grid(row=2, column=2, padx=5)

        # Buttons for Play, Train, and Test
        tk.Button(root, text="Play Game", command=self.play_game).grid(row=3, column=0, padx=10, pady=10)
        tk.Button(root, text="Train Model", command=self.train_model).grid(row=3, column=1, padx=10, pady=10)
        tk.Button(root, text="Test Model", command=self.test_model).grid(row=3, column=2, padx=10, pady=10)

    def load_file_dialog(self):
        filename = filedialog.askopenfilename(title="Select Load File", filetypes=[("XML Files", "*.xml")])
        if filename:
            self.load_file_entry.delete(0, tk.END)
            self.load_file_entry.insert(0, filename)

    def save_file_dialog(self):
        filename = filedialog.asksaveasfilename(title="Select Save File", defaultextension=".xml", filetypes=[("XML Files", "*.xml")])
        if filename:
            self.save_file_entry.delete(0, tk.END)
            self.save_file_entry.insert(0, filename)

    def play_game(self):
        # Placeholder for the function to play the game
        messagebox.showinfo("Play Game", "Game started!")
        self.wrapper.playGame()

    def train_model(self):
        try:
            episodes = int(self.episodes_entry.get())
            save_file = self.save_file_entry.get()
            load_file = self.load_file_entry.get() if self.load_file_entry.get() else None

            # Add training model functionality here
            messagebox.showinfo("Train Model", f"Training model for {episodes} episodes\nSave to: {save_file}\nLoad from: {load_file}")
            self.wrapper.trainModel(save_file, load_file, n_episodes=episodes)

        except ValueError:
            messagebox.showerror("Input Error", "Please enter a valid number for episodes.")

    def test_model(self):
        load_file = self.load_file_entry.get()
        if not load_file:
            messagebox.showerror("Input Error", "Please specify a file to load the policy from.")
            return

        # Add testing model functionality here
        messagebox.showinfo("Test Model", f"Testing model with policy loaded from: {load_file}")
        self.wrapper.testModel(load_file)

# Initialize the Tkinter root and menu
root = tk.Tk()
menu = CustomCarRacingMenu(root)
root.mainloop()
