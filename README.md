# Chaotic Classes - Multi-Class Brawler (WIP)
Hi! This is a multiplayer game I've been building in Godot 4.6.x. The main idea is a top-down arena fighter where 1-4 players randomly "transform" into different classes (like Archer, Melee, etc.) during the match and fight in a best-of-three format. The game will also include a solo, "swarm" sandbox mode with optional creative control to try out or practice the different classes.

I'm using this project to learn how Godot's High-Level Multiplayer API works, especially handling things like server-authoritative spawning and state syncing. As my first Godot project, I'm slowly learning the fundamentals of gameplay loops, multiplayer synchronization, and character balancing to ensure the combat feel stays fast-paced and fair for all players.

### 🛠️ How it works (The Technical Stuff)
* **Multiplayer Spawner:** Only the Host can actually spawn player nodes via Godot's MultiplayerSpawner node. It makes sure everyone’s game looks the same and prevents "double-spawning" bugs.
* **Syncing:** Every player has a MultiplayerSynchronizer node that handles moving and animations across the network.
* **Match Loop:** ClassManager, GameManager and PlayerManager scripts designed with custom sequences to handle the core gameplay loop, such as handling transformations, cleaning up the old player nodes, updating the player information in the StageManager Autoload, and handing match restarts.
---
### 🎨 Assets & Credits
Almost all the art and assets are drawn by me and a friend in *Aseprite*. Other free resources used in the project are:
* **Character Sprites:** The base character sprite is modeled after [Artist's] sprite.
* **Tileset:** The tileset is custom drawn using several online resources as guidance and inspiration.
* **UI:** Most of the UI elements are directly from [Kenney](www.kenney.nl) or inspirted by their art. These are licensed under **Creative Commons CC0**.
---
### 📜 Legal & License
* **My Code:** You're free to look at my .gd scripts to see how I handled the networking, but please do not re-sell the whole project as your own.
* **Third-Party Assets:** All assets (images/sounds) belong to their respective creators. I've included their license files in the /Licenses folder just to be safe.
