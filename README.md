# godot-agents

## Project summary

### One-sentence description of the project

Reinforcement machine learning agents designed to complete a video game in the godot engine and a game to be used the next year.

### Additional information about the project

This project aims to introduce K-12 students to the concepts of Reinforcement Machine Learning (RML). Our team is tasked with designing an agent for the current draft game and providing supporting documentation for students, along with a feedback document for the results of a trial event in December. Each team member will also design a new game for the following year, exploring different genres to show the diverse range of RML agents. Through this, students will gain foundational knowledge on Machine Learning and AI, preparing them for future challenges in a technology-driven world.

We are planning on implenting two reinforcement learning algorithms that will be documented and used to solve a game in Godot
The first agent will utilize Monte Carlo techniques, and the second agent will use the REINFORCE Policy Gradient algorithm.

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
  - Modify the provided scripts in Godot to adjust the agent's behavior and learning logic.

## Additional Documentation

Links to additional documentation:
  * [Sprint reports](https://github.com/luwke1/godot-agents/blob/3494a113362c707e003035cf26cbd5e27b47e756/sprint_reports/sprint_report_1.md)
  * [Sprint 1 Demo Video](https://youtu.be/SGdJZU3_xYI?si=VPmMmzRrqxQv_Naq)
  * [Tool to download parts of repo](https://download-directory.github.io/)



## License

https://github.com/luwke1/godotgame/blob/main/LICENSE.txt
