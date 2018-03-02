---
layout : post
title: "Using the pebble watch to display stock quotes"
date: 2013-08-26 11:34:00
categories: pebble android
biofooter: true
bookfooter: false
---

I’ve always been intrigued by books like “Reminiscences of a stock operator” where trading is based on continually watching a market and developing a “feel” for it. Having spent a lot of time experimenting with them, i’m generally skeptical of automatic rule based trading systems but remain intrigued about entirely discretionary, immersion based systems.

<!--more-->

My intrigue primarily comes from experiments with compass belts. In these people wear a belt with vibrating pads, setup such that whichever pad is facing north will lightly vibrate. Over relatively short spaces of time, wearers are observed to incorporate this additional “sense” and develop augmented senses of direction and navigation, for example being able to backtrack along complex routes where they would previously have been incapable of doing so.

The problem with applying this to the movements of financial instruments has always been obtaining immersion. Failing a desire – and the free time – to sit and watch stock tickers continually, what is the most efficient way to gain an “awareness” of a given metric and potentially as a result gain an awareness of when particular movements are likely?

The pebble watch provides the opportunity to use that space on our wrist traditionally devoted to time to monitor whatever figures we choose. When I’m running or cycling it shows my pace and distance but outside of those times it simply shows the time – something I’m rarely interested in knowing. In this experiment I will create simple Android and Pebble applications which pull the level of the FTSE100 from Google Finance and display it (and only it) on the screen of the pebble continually.

## Getting the quotes

This is fairly simple, Google Finance provides a simple (if undocumented) api for accessing stock quotes, a URL such as the following:

<http://finance.google.com/finance/info?client=ig&q=INDEXFTSE%3aUKX>

Will return a response in the format:

``` javascript
[ { "id": "12590587" ,"t" : "UKX" ,"e" : "INDEXFTSE" ,"l" : "6,499.99" ,"l_cur" : "£65.00" ,"s": "0" ,"ltt":"4:35PM GMT+1" ,"lt" : "Aug 16, 4:35PM GMT+1" ,"c" : "+16.65" ,"cp" : "0.26" ,"ccol" : "chg" } ]
```

where q in the url is the url escaped representation of the Google Finance ticker and l in the returned JSON is the 20 minute delayed level of the instrument.

## Making it happen

The source for an app to get the quotes and push the quotes to a pebble watch is available here:

<https://github.com/TalkingQuickly/pebble_stock_android>

The source for a pebble app to receive the quotes is available here:

<https://github.com/TalkingQuickly/pebble_stock>

## Resources

This was also my first attempt at writing a native Android App (and several years since I last wrote Java) and I relied heavily on this article (http://technicalmumbojumbo.wordpress.com/2012/01/19/android-tutorial-restful-webservices-google-maps-integration/) for guidance on how to access a restful api from an Android App.

## Get in Touch

If you'd like to chat further about the ideas in the post, get in touch
on twitter, <http://www.twitter.com/talkingquickly>
