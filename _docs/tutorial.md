---
title: Tutorial
layout: docs
permalink: /docs/tutorial.html
---

<div class="note">
  This guide assumes you have <a href="http://cocoapods.org/" alt="CocoaPods">Cocoapods</a> installed and running.
</div>

The best way to get started is by building stuff. Here, we walk you through a tutorial to build your own Awesome Magazine - A feed of articles. Here's what the finished version looks like:

Scaffolding

Before we get started, let's set up a few things.

1. Create a directory for your Xcode project called `AwesomeMagazine` and create AwesomeMagazine.xcodeproj inside it - an empty project.
2. In the `Podfile` add a line

        pod 'ComponentKit', '~> 0.9'

    and run `pod install` to get yourself set up.

