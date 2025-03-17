# Sprint 5 Report (February 10 - March 17 2025)

## YouTube link of Sprint 5 Video (Make this video unlisted)

https://youtu.be/7nf03vt6HKM

## Wix website and tutorial videos created during this sprint
* https://coleclark75.wixsite.com/beginnerrml
* https://www.youtube.com/@GodotAgents

## What's New (User Facing)
* Added DQN agent to the moving platform game
* Added DQN agent to the game with enemies
* Created a Wix website for tutorial videos
* Made the first 4 videos including:
*   The fundamentals of reinforcement learning
*   Q learning overview
*   Deep Q-Network overview
*   Godot install and running an example project

## Work Summary (Developer Facing)
We each created two videos and put them on a Wix website. We each added a DQN agent to one of the modified games. Training the agents on these new games was difficult, and modifications to the reward functions could help the DQN agents learn faster.

## Completed Issues/User Stories
Here are links to the issues that we completed in this sprint:
* [Godot Environment Setup Learning Video](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=101702522&issue=luwke1%7Cgodot-agents%7C64)
* [Deep Q-Networks (DQN) Learning Video](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=101702452&issue=luwke1%7Cgodot-agents%7C63)
* [Q-Learning Explanation video](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=101702361&issue=luwke1%7Cgodot-agents%7C62)
* [Introduction to Reinforcement Learning Video](https://github.com/users/luwke1/projects/2?pane=issue&itemId=101702243)
* [Report Draft 2](https://github.com/users/luwke1/projects/2?pane=issue&itemId=97095634)
* [Game moving platform modification](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=97095795&issue=luwke1%7Cgodot-agents%7C53)
* [Setup Wix Site for Videos](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=102179334)
* [Game enemy modification DQN](https://github.com/users/luwke1/projects/2/views/1?pane=issue&itemId=102414181)

  story points Cole 30, Luke 30
  
## Code Files for Review
Please review the following code files, which were actively developed during this
sprint, for quality:
* [DQNFireball.gd](https://github.com/luwke1/godot-agents/blob/new-game-dqn/Fireball_enemy_mod/DQN_Agent_Fireball/DQNFireball.gd)
* [dqnAgent.gd](https://github.com/luwke1/godot-agents/blob/new-game-dqn/Moving_platform_mod/dqnAgent.gd)
* [level.gd](https://github.com/luwke1/godot-agents/blob/new-game-dqn/Moving_platform_mod/level.gd)
* [human_player.gd](https://github.com/luwke1/godot-agents/blob/new-game-dqn/Moving_platform_mod/human_player.gd)
* [player_factory.gd](https://github.com/luwke1/godot-agents/blob/new-game-dqn/Moving_platform_mod/player_factory.gd)
* [wrapper.py](https://github.com/luwke1/godot-agents/blob/main/Q_Learning_Example/wrapper.py)
* [main.py](https://github.com/luwke1/godot-agents/blob/main/Q_Learning_Example/main.py)
* [Q_agent.py](https://github.com/luwke1/godot-agents/blob/main/Q_Learning_Example/Q_agent.py)

## Retrospective Summary
Here's what went well:
* creating the videos

Here's what we'd like to improve:
* dqn agent performance on modified games

Here are changes we plan to implement in the next sprint:
* add the rest of the videos
* improve website
* improve dqn agent performance on new games
