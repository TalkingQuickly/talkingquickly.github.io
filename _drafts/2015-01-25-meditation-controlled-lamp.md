---
layout : post
title: "Meditation Controlled Lamp"
date: 2015-1-25 22:16:00
categories: qs meditaiton tessel
biofooter: true
bookfooter: false
---

Taking up Meditation is one of the single easiest things an individual can do to decrease their stress levels, sleep better and generally improve well-being. It's also difficult, like any habit, to stick to doing it regularly. One of the most effective ways of turning something into a habit is linking it to your daily routine. To this end we've created a bedside lamp which can be turned on and off by meditating. This post explains exactly how we did it and what's needed to replicate it.

This began as a project created by myself [@talkingquickly](http://www.twitter.com/talkingquickly) and James [oldwhitewizard](http://www.twitter.com/oldwhitewizard) for Seedhack IOT 2015. The result looked like this:

@TODO PHOTO

Particular Kudos to James for the awesome 3D printed case.

And the video below shows it in operation:

@TODO VIDEO

We used the following components and services:

* A Mindwave EEG Headband (although we're planning on replacing this with a home built sensor as [demonstrated here](http://www.instructables.com/id/DIY-EEG-and-ECG-Circuit/?ALLSTEPS)
* A Tessel Microprocessor with WiFi
* An Android Phone
* 3 Generic NPN Transistors, some breadboard, 10K resistors and wire
* A cluster of Red, Green and Blue LED's (we used [these](http://www.maplin.co.uk/p/set-of-4-rgb-led-cabinet-lights-a49lw) but most LED light sets are hackable
* A 3D Printed case, optional but much cooler!
* PubNub for real time message passing

## Wiring up the LED's

The Arduino's PWM outputs can only handle quite a small current load, so a simple transister circuit allows for larger loads - such as large LED clusters - to be controlled. The circuit used is [documented here](https://learn.adafruit.com/adafruit-arduino-lesson-13-dc-motors/transistors) and a photo of our final layout is show below:

@TODO PHOTO

## Connecting them to the Tessel

The tessel provides 3 Pulse Width Modulated (PWM) outputs which can be used to simulate an analogue voltage to control the level of the lights. :w

## Triggering the Tessel from PubNub Data

## An Android app to get data from the Mindwave

## Pushing data from the Android App

## A Web Interface

## The Finished Product

## The Next Version(!)
