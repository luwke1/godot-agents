# godot-agents

## Project summary

### One-sentence description of the project

Godot Agents is an educational initiative that uses reinforcement learning agents to teach K-12 students the fundamentals of machine learning through interactive games built in Godot.

### Additional information about the project

This repository contains implementations of reinforcement learning algorithms, specifically a Deep Q-Network (DQN) agent (in the `DQNAgent` branch) and other experimental setups in the main branch. The project aims to make machine learning accessible and engaging for students by demonstrating how agents can learn to play games through trial and error.

## Installation

### Prerequisites

Here are the future prerequisites that will be required to run our project.

### 1. Godot Game Engine
- **Version**: Godot 4.2 or higher
- [Download Godot](https://godotengine.org/download)
- Godot will serve as the platform where the agents interact with the game environment.

### 2. Python
- **Version**: Python 3.7 or higher
- [Download Python](https://www.python.org/downloads/)
- Python will be used to implement and test the reinforcement learning algorithms before integration with Godot.

### 3. TensorFlow or PyTorch
- Choose either [TensorFlow 2.x](https://www.tensorflow.org/install) or [PyTorch 1.x](https://pytorch.org/get-started/locally) for building and training neural networks.
  
  - To install TensorFlow:
    ```bash
    pip install tensorflow
    ```
  - To install PyTorch:
    ```bash
    pip install torch
    ```

### Godot DQN Agent Installation Steps

1. Clone the repository and switch to the DQNAgent branch:
   ```bash
   git clone -b DQNAgent https://github.com/luwke1/godot-agents.git
   cd godot-agents
   ```

2. Open the project in Godot:
   - Launch Godot.
   - Click on "Import" and navigate to the `godot-agents` folder.
   - Select the `project.godot` file and import it.

3. Run the game:
   - Press the Play button in Godot to test the environment.

4. Observe the DQN agent in action:
   - The DQN agent's logic and behavior will be demonstrated in the imported game environment.

## DQN Agent Functionality

- **Run the DQN Agent**:
  - Observe the pre-configured DQN agent interacting with the game environment.

- **Train the DQN Agent**:
  - Begin training of the DQN Agent and save training results to file system.

- **View Documentation of Agent**:
  - Button to view the documentation of the current agent.

- **Customize the Agent**:
  - Modify the provided scripts in Godot to adjust the agent's behavior and learning logic


### Prerequisites for Egg Drop Game

This project requires
- Python 3.7 or higher
- numpy
- pytorch
- gymnasium
- matplotlib
- pandas
- pygame
- box2d

The above libraries can be installed using
```bash
pip install numpy
pip install torch torchvision torchaudio
pip install gymnasium
pip install matplotlib
pip install pandas
pip install pygame
pip install gymnasium[box2d]
pip install box2d-py
```


### Egg Drop Game Installation Steps

clone the repository, navigate to custom_LL_egg_game, run main
  ```bash
  git clone https://github.com/luwke1/godot-agents.git
  cd godot-agents/custom_LL_egg_game
  python3 main.py
   ```

## Egg Game Functionality

- **Play Game**:
  - allows the user to play the game without the agent

- **Train Q Agent**:
  - Trains the Q agent on the number of steps in the "Number of Steps for Training" box

- **Test Q Agent**:
  - Runs a trained Q agent on the environment once and returns the result.
  - The "Load Policy File" box must be filled in with the path of a trained Q agent
 
- **Train PPO Agent**:
  - Trains the PPO agent on the number of steps in the "Number of Steps for Training" box

- **Test PPO Agent**:
  - Runs a trained PPO agent on the environment once and returns the result.
  - The "Load Policy File" box must be filled in with the path of a trained PPO agent

- **How to Play**:
  - explains the controls and points system for the game
 
- **Documentation**:
  - Opens a web browser to the documentation of the game and agents

- **Exit**:
  - closes the menu

## Additional Documentation

Links to additional documentation:
  * [Sprint reports](https://github.com/luwke1/godot-agents/blob/3494a113362c707e003035cf26cbd5e27b47e756/sprint_reports/sprint_report_1.md)
  * [Sprint 1 Demo Video](https://youtu.be/SGdJZU3_xYI?si=VPmMmzRrqxQv_Naq)
  * [Tool to download parts of repo](https://download-directory.github.io/)



## License

https://github.com/luwke1/godotgame/blob/main/LICENSE.txt
