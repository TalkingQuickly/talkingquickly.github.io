---
layout : post
title: "Reading Git Merge Conflicts"
date: 2014-3-13 19:36:00
categories: dev
biofooter: false
bookfooter: true
---

Git merge conflicts are something any developer who works in a team bigger than one, has to deal with from time to time. It's surprisingly common it seems to deal with these without really understanding what's going, I did for years and I know many others who still are.

<!--more-->

In a typical scenario, after running `git pull origin develop` we find that instead of the friendly `merge completed by something` type message we'd expected, we get something like:

    Automatic merge failed; fix conflicts and then commit the result.

For many developers, fixing this remains something of a black art. The listed files with conflicts will contain a variety of `<<<<<<` and `=====` lines and we can normally work out which ones to delete through common sense. Phew, having to find out what all the `<<<<`'s mean has been avoided once again.

The notation is actually really simple and understanding it makes fixing these conflicts far quicker, without the need for any sort of graphical merge tool.

Let's say we see the following merge conflict:

     <<<<<<< HEAD
     The ninth line is amazing
     =======
     The ninth line is great
     >>>>>>> 4e2b407f501b345688a4565acafffa022fythd8

The text between `<<<<<<< HEAD` and `=======` is what is contained in the current HEAD changeset. In general, unless you were doing something really fancy, this will be the same as what was in your current working directory before you initiated the merge. So really simplistically, if we're merging someone else's changes into our own, this bit is what was in our file before we started.

The next bit, between `=======` and `>>>>>>>` is what was in the changeset you are merging in. So to take our really simple "merging their code into ours" example, this is "their" code. The `4e2b407f501b345688a4565acafffa022fythd8` is the commit reference of "their" code, e.g. what's being merged in.

With this in mind, we can now choose to either delete their changes, delete our changes, or keep both.
