# MGA - Mester's Grand Arcade (Super Mario Bros Reference) in Godot
made by: Itay Hoban & Oren Hassid 😎

This project is a Reference of the classic *Super Mario Bros.* game, originally released by Nintendo in 1985 for the NES, built using the Godot V4.4 game engine. It aims to replicate the core gameplay mechanics, including Mario's movement, enemy interactions, and interactive blocks And even improve and add functionality. while leveraging Godot's 2D capabilities. Here an overview of the project, setup instructions, gameplay details, and a breakdown of the code structure.

## Features

- **Player Controls**: Mario can run, jump, crouch, and shoot fireballs (when powered up), with smooth physics-based movement.
- **Player States**: Supports three states:
  - **Small Mario**: Basic form with single jumps.
  - **Big Mario**: Taller form with crouching and breaking brick blocks.
  - **Shooting Mario**: Can shoot fireballs to defeat enemies.
- **Enemies**:
  - **Goombas**: Simple enemies that die when stomped.
  - **Koopa Troopas**: Retreat into shells when stomped, which can then be kicked.
- **Interactive Blocks**:
  - **Brick Blocks**: Breakable (by Big Mario) or bumpable for effects.
  - **Question Mark Blocks**: Yield coins or power-ups when hit.
- **Power-ups**:
  - **Mushroom**: Transforms Small Mario into Big Mario.
  - **Shooting Flower**: Grants fireball-shooting ability.
- **Physics and Collisions**: Realistic 2D physics with collision detection for enemies, blocks, and the environment.
- **Animations**: Pixel-art animations for Mario's actions (running, jumping, crouching, shooting, etc.).
- **Camera Sync**: A camera that follows Mario horizontally through the level.
- **Scoring**: Points awarded for stomping enemies, displayed with floating labels.

## Screenshots

main MENU:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/0.png?raw=true)

level 1:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/1.png?raw=true)

level 2:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/2.png?raw=true)

level 3:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/3.png?raw=true)

level 4:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/4.png?raw=true)

level 5:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/5.png?raw=true)

level 6:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/6.png?raw=true)

level 7:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/7.png?raw=true)

level 8:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/8.png?raw=true)

level 9:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/9.png?raw=true)

level 10:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/10.png?raw=true)

level 11:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/11.png?raw=true)

level 12:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/12.png?raw=true)

Game Over:

![image alt](https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade/blob/main/screenshuts/13.png?raw=true)


## Installation and Setup

To run this project locally, follow these steps:

1. **Prerequisites**:

   - Godot Engine (version 4.0 or higher). Download it from godotengine.org.
   - Windows 10 (version 21H1 or higher).

2. **Clone the Repository**:

   ```bash
   git clone https://github.com/nuro1701/MGA---Mester-s-Grand-Arcade
   ```

3. **Open in Terminal**:

   - Write npm install express mongoose cors.
   - Write node server.js

4. **Open in Godot**:

   - Launch Godot and select "Import" from the Project Manager.
   - Navigate to the cloned repository and select the `project.godot` file.
   - Click "Import & Edit" to open the project.

4. **Run the Game**:

   - Press the "Play" button (F5) in the Godot editor to launch the game.
   - Alternatively, select a specific scene (e.g., `Main.tscn`) and press "Play Scene" (F6).

## How to Play

### Controls

- **Left Arrow / A**: Move Mario left.
- **Right Arrow / D**: Move Mario right.
- **Up Arrow/ W**: Jump (or shoot upward if in Shooting mode).
- **Down Arrow/ S**: Crouch (Big Mario only) or perform a downward action.
- **Space/ Ctrl**: Shoot fireballs (Shooting Mario only).

### Gameplay

Each level requires killing enemies, collecting coins, jumping on blocks, and reaching the finish line.

At the end of each level, there is a trivia question about some historical topic.

Moreover, when the player is inactive for 30 seconds, every few seconds the screen flashes to get his attention.

In addition, we collect real-time information about the player, save it on the server, give it a score, and determine the difficulty level of the level based on the score.



### Assets

All images, animations, designs, items in stages, background music, and other sound clips were created and edited by us in Photoshop, Illustrator, and Virtual DJ and are original to this game.


---

*Built with ❤️ using Godot Engine.*
