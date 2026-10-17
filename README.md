# Tile

Tile is a Lua shell for the Minecraft mod CC:Tweaked on Minecraft 1.20.1. It opens to a grid of square icons. One app fills the screen at a time. The same program runs on a normal computer, an advanced computer, a pocket computer, an advanced pocket computer, and a monitor.

Advanced screens draw icons in color. Basic screens draw the same shapes in white, light gray, gray, and black. An advanced screen can be switched to gray in Settings. A basic screen stays gray.

## Run the tests

The tests use Lua on your own computer. They do not launch Minecraft.

```bash
sudo apt-get update
sudo apt-get install -y lua5.1 lua5.4
lua5.1 tests/run.lua
lua5.4 tests/run.lua
```

Both commands should print a `PASS` line for every test and exit 0.

## Install it on a computer

Tile's files live in this project until you copy them onto an in-game computer. Each computer has its own files. The mod also stores them in the world folder at `computercraft/computer/<id>/`.

1. Copy `install.lua` and the `os` folder onto a floppy, or into that computer's save folder while the world is closed.
2. In the computer, run:

```
/disk/install.lua
```

Use the path where `install.lua` actually is. If `startup.lua` already exists, Tile asks `Replace startup.lua? (y/n)`.
3. Reboot the computer. CC:Tweaked runs `startup.lua`, which runs `/os/main.lua`. Tile is now what opens on every boot.

You can start it once without installing by running `/os/main.lua` after the `os` folder is already on the computer.

Exit to CraftOS from Settings lasts until the next boot. The next boot opens Tile again because `startup.lua` is still there.

## Controls

- Click an icon, or the five-character name under it, to open that app. Advanced computers, advanced pocket computers, and monitors can do this.
- A normal computer and a normal pocket computer have no mouse. Arrow keys and Enter are on: the highlighted name is white on black, and Enter opens it. The same keys work in Files and Settings. On an advanced computer or advanced pocket computer those keys are off until Settings says `Keys: On`. Shell still uses normal CraftOS typing either way.
- The top row is the bar. On the home screen it says `Tile`. When more than one page of icons exists, `<` and `>` sit at the right. Arrow keys also move onto the next page.
- While an app is open, `Home` is in the first four columns of the bar. Home always returns to the grid.
- Press Ctrl+T inside an app to return to the grid. Press Ctrl+T on the grid to leave Tile and drop into CraftOS. A tap is enough. The stop button on the computer screen does the same thing.
- Ctrl+R and Ctrl+S stay the mod's reboot and shutdown. Tile does not call them.
- A monitor is clicked in the world. That is a different event from a click inside the computer screen, and Tile listens for the one that matches the screen it is drawing on.
- Keys still come from the computer or pocket screen. Open that screen when an app such as Shell or edit needs the keyboard, even if the picture is on a monitor.

## Screens

Tile draws on the terminal it was started on. `monitor left /os/main.lua` draws on that monitor. Settings can move the picture later. The choice is saved in `/.tile` and survives a reinstall.

Tile does not change a monitor's text scale. A screen smaller than 15×10 characters shows `Screen too small`, `Lower text scale`, and `or add blocks`. If the computer itself is large enough, that message has a `Use computer` button and the computer shows the normal grid. A missing monitor drops back to the computer and clears the saved choice.

A pocket computer uses its own 26×20 screen. A desktop computer uses its own 51×19 screen unless a monitor was selected.

## Apps

Files, Shell, and Settings ship with Tile. Settings appears on the grid as `Sett.` because a cell holds five characters.

- Files starts at `/`. Folders are listed first. A `.lua` file runs. Any other file opens in the normal `edit` program. Leaving that program returns to Files. Inserting or removing a floppy refreshes the list.
- Shell is the normal CraftOS prompt. `exit` returns to the grid.
- Settings shows `Screen: Color` or `Screen: Gray`, lists `This screen` and any attached monitors, and asks before Exit to CraftOS.

Add another app on that in-game computer:

```
/apps/notes/main.lua
/apps/notes/label
/apps/notes/accent
/apps/notes/icon.nfp
```

`main.lua` is required. `label` is the name under the icon, shortened to five characters. `accent` is a CC color name such as `cyan`, `red`, or `lime`. If it is missing or unknown, the accent is cyan.

`icon.nfp` is exactly two lines of three hex digits:

```
0b0
000
```

The digits follow the normal CC paint palette: `0` white, `8` light gray, `f` black, and `b` blue. Blue is the accent placeholder. Tile recolors it on an advanced screen and draws it gray on a basic screen. A missing or broken icon becomes a letter on a white tile.

User apps are listed after the three built-ins, sorted by label. Two computers in one world do not share `/apps`.
