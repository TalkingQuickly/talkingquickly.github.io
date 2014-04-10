---
layout: page
title: Sublime Text
---

## My Origami Config

Leader: `Super + K`

* Leader, `super + hjkl` (vim bindings) - Move pane focus
* Leader, `shift + hjlk` (vim bindings) - Move current file to pane
* Leader, `super + e` - Zoom current pane
* Leader, `super + q` - Unzoom current pane
* Leader, `w` - Destroy current pane
* Leader, `s`,`v` - Create a new pane to the right (split vertically)
* Leader, `s`,`h` - Create a new pane below (split horizontally)

## I18n Snippets:

In User Key Bindings

    { 
     "keys" : ["ctrl+shift+t"], 
     "command" : "insert_snippet",
     "args": {
     "contents": "t(:\"${0:$SELECTION}\")"
     }
    },
    { 
     "keys" : ["ctrl+shift+e"], 
     "command" : "insert_snippet",
     "args": {
     "contents": "<%= ${0:$SELECTION} %>"
     }
    }
