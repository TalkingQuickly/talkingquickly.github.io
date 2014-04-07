---
layout: page
title: Tmux Sublime Plugin
---

Aim is to create a Sublime Text plugin which allows a keyboard shortcut to be used to open a terminal window and resume or create a tmux session with a name matching the project name.

This would probably be a fork of the excellent sublime_terminal plugin <https://github.com/wbond/sublime_terminal>

## Resources

Various approaches to attach or create: <http://stackoverflow.com/questions/3432536/create-session-if-none-exists>

Simplest seems to be: `tmux attach -t some_name || tmux new -s some_name`