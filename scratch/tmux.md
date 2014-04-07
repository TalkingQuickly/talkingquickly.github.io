---
layout: page
title: TMux Cheatsheet
---

## Commands

Create a new session:

    tmux new -s NAME

Resume a session

    tmux attach -t NAME

Show a list of sesssions:

    tmux list-sessions

## Shortcuts

### Splits/ Panes

* prefix `"` - split pane horizontally.
* prefix `%` - split pane vertically.
* prefix `arrow key` - switch pane.
* prefix `o` - cycle pane focus
* prefix `space` - Cycle layouts
* prefix `x` - Kill current pane (with confirmation prompt)
* prefix without releasing and `arrow keys` - resize pane.
* prefix without releasing and `o` - switch contents of panes

### Windows

* prefix `c` - (c)reate a new window.
* prefix `n` - move to the (n)ext window.
* prefix `p` - move to the (p)revious window.

### Sessions

* prefix `d` - Dettach from the current session
* prefix `s` - Show a list of windows in the current session

## Config

Main config file is
    
    ~/.tmux.conf

Change Prefix to Ctrl+A (same as screen):

    set -g prefix C-a