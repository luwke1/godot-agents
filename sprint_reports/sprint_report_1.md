# Sprint 1 Report (8/26/24 - 10/5/2024)

## What's New (User Facing)
 * Simplified Monte Carlo algorithm
 * Monte Carlo description
 * policy gradient plan

## Work Summary (Developer Facing)
In Sprint 1, our primary focus was on building foundational knowledge of reinforcement learning (RL) algorithms, specifically to prepare for the implementation of two RL agents: one using the policy gradient REINFORCE algorithm and another using Monte Carlo methods. The team spent significant time to researching RL concepts, exploring how to integrate these algorithms with Godot, and identifying the necessary libraries and resources for implementation. We faced a few barriers in the process, particularly in understanding the constraints of Godot’s engine for machine learning tasks, as it isn’t inherently built for integration with most reinforcement learning algorithms. This required us to explore potential workarounds, such as using external libraries (like TensorFlow or PyTorch) and finding ways to interface them with Godot. Another significant barrier that we overcame was understanding the challenges of connecting an RL agent with a game engine in real time, however, with significant learning in RL algorithms and the Godot game engine, we believe we are ready to start implementing these agents.

## Unfinished Work
We are currently missing a team member, so we were unable to complete an outline and plan for a 3rd Reinforcement Learning Agent. Overall, everything else was completed for Sprint 1, and we are ready to begin on Sprint 2.

## Completed Issues/User Stories
Here are links to the issues that we completed in this sprint:

 * [Simplified Policy Gradient algorithm plan](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=82255932)
 * [Learn Policy Gradient REINFORCE method](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=82238359)
 * [Learn Reinforcement Fundamentals](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=82238108)
 * [Team Inventory](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=82033740)
 * [Requirements and Specifications](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=82034583)
 * [Simplified Monte Carlo Algorithm](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=82033188)
 * [client documentation - Monte Carlo description](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=82261972)

   Cole: 18.5 story points
   
   Luke: 20.5 story points
 
 ## Incomplete Issues/User Stories
 Here are links to issues we worked on but did not complete in this sprint:
 
 * [Policy Gradient RL Agent Python Code](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=82135261) < Not necessary for Sprint 1, only an outline and plan of agent required >
 * [Duncan RML agent simplified](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=82033740&pane=issue&itemId=82261692) < Duncan did not contribute to this sprint >
 * [client documentation - Duncan RML algorithm](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=82033740&pane=issue&itemId=82262011) < Duncan did not contribute to this sprint >

## Code Files for Review
Please review the following code files, which were actively developed during this sprint, for quality:
 * [board.py](https://github.com/luwke1/godot-agents/blob/23bdbfa546baf0c8228cf789a594f8c517f1f1ce/simplified_algorithms/board.py)
 * [monte_carlo_agent.py](https://github.com/luwke1/godot-agents/blob/23bdbfa546baf0c8228cf789a594f8c517f1f1ce/simplified_algorithms/monte_carlo_agent.py)
 * [main.py](https://github.com/luwke1/godot-agents/blob/23bdbfa546baf0c8228cf789a594f8c517f1f1ce/simplified_algorithms/main.py)
 
## Retrospective Summary
Here's what went well:
  * We learned about RML algorithms
  * simplified Monte Carlo algorithm
  * policy gradient plan
 
Here's what we'd like to improve:
   * communication with team member Duncan
   * keeping our Kanban board updated
  
Here are changes we plan to implement in the next sprint:
   * Update the Kanban board when new issues come up or tasks are completed
