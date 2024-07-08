# Pac-Man Game

## Overview
This project implements a text-based version of the classic Pac-Man game using assembly language (assuming x86 architecture). The game features multiple levels, score tracking, and ghost AI movement.

## Setup
1. **Environment**: Ensure you have an assembler compatible with x86 assembly language. This code is designed for environments like MASM (Microsoft Macro Assembler).
2. **Dependencies**: Ensure the necessary include files (`Irvine32.inc`, `macros.inc`) and libraries (`kernel32.lib`, `user32.lib`, `Winmm.lib`) are correctly included and linked.
3. **Compilation**: Use the assembler to compile the main assembly file (`pacman.asm`).
4. **Execution**: Run the compiled executable to start the game.

## Instructions
- **Controls**: Use arrow keys (up, down, left, right) to navigate Pac-Man through the maze.
- **Objective**: Collect all the dots ('.') while avoiding the ghosts ('O'). Each dot increases your score.
- **Levels**: There are multiple levels to play through. Complete each level by clearing all dots to proceed.
- **Game Over**: You have three lives. Losing all lives by colliding with a ghost ends the game.

## Files
- **pacman.asm**: Main assembly code file containing game logic.
- **map.txt, map2.txt, map3.txt**: Game board configuration files for each level.
- **art.txt, art2.txt**: ASCII art files used in the splash screen.
- **player.txt**: File to store player information (name).
- **DirectionFile.txt**: File containing game instructions for players.

## Credits
- **Author**: Shaheer-E-Haq

## Notes
- Ensure all files (`map.txt`, `art.txt`, etc.) are in the same directory as the executable for proper game functioning.
- Modify `BUFFER_SIZE`, `boardWidth`, and other constants as needed for different game configurations.

## Future Improvements
- Implement additional game features such as power pellets, more complex ghost AI, or customizable game levels.
- Enhance user interface with graphical elements or sound effects.

Enjoy playing Pac-Man!

