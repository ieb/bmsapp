# BMS App

This is an experiment with Google Stitch and the Google AntiGravity. To build an app for montoring a battery management system (BMS) for a LiFePo4 battery pack. No code was written by a human, and it is not in a finished state due to runnign out of tokens in all the available Google models after 4h. 

# Why ?

I read that Linus was using Stitch and AntiGravity to build guitar effects pedals. I was inspired to try it out, but I wanted to do it with a language I dont know about. I also did not want to try and design the UI/UX of the app since does not come naturally to me, and I wanted to use a framework (Flutter) I was not familiar with. All to test if AntiGravity really could allow a non programmer with an idea to build a mobile app.

# The app

This is a mobile app that will montor the state of a LiFePo4 battey pack controlled by a BMS. I am interested in seeingthe overall state of the battery including state of charge, current and voltage. I am also interested in being able to see the detail including internal temperatures and individual cell voltages. The connection to the battery pack with allow connection to the BMS direct over BLE, but also a connection to a stream of Can bus messages over http using the Seasmary protcol. Although these are low level implementation details please include UI to control both types of connection. Feel free to ask me anything where is is not clear.


## Stitch Project URL
    https://stitch.withgoogle.com/projects/11141352492501134303

# AntiGravityies Brain and my experince insteractin with it.

AntiGravity stores its "brain" under ~/.gemini/antigravity/brain. A snapshot of the brain can be found antigravity_session folder. It contains the implementation plans it created, and the tasks as well as the Walktrhoughts after each stage.

Initially I started with Gemini 2.5 Pro (High) with the agent in planning mode. It was solid but slow. Then I enabled the chrome AntiFravity extension and asked the agents to test for itself, which it did, clicking on buttons, navigating and taking screenshots, which quickly consumed the free tier token quota. Then I switched to Gemini 3 Flash which was much faster, more concise and able to drive chrome, however it struggled to find the buttons to click and would go into loops.

## Walkthroughs

Initial planning and implementation     with Gemini 2.5 Pro

* (brainSnapshot-20260118/walkthrough.md.resolved.0.md)
* (brainSnapshot-20260118/walkthrough.md.resolved.1.md)
* (brainSnapshot-20260118/walkthrough.md.resolved.2.md)
* (brainSnapshot-20260118/walkthrough.md.resolved.3.md)
* (brainSnapshot-20260118/walkthrough.md.resolved.4.md)
* (brainSnapshot-20260118/walkthrough.md.resolved.5.md)
* (brainSnapshot-20260118/walkthrough.md.resolved.6.md)
* (brainSnapshot-20260118/walkthrough.md.resolved.7.md)

Swithed to Flash 3 and started to let the agent drive chrome.

* (brainSnapshot-20260118/walkthrough.md.resolved.8.md)
* (brainSnapshot-20260118/walkthrough.md.resolved.9.md)
* (brainSnapshot-20260118/walkthrough.md.resolved.10.md)
* (brainSnapshot-20260118/walkthrough.md.resolved.11.md)
* (brainSnapshot-20260118/walkthrough.md.resolved.12.md)
* (brainSnapshot-20260118/walkthrough.md.resolved.13.md)

## Result

The net result is that after about 4 hours, some of which was unsupervised, going shopping, having a shower etc, most of the functionality is present and tested. Low level BLE protocols are implemented. I have not run the app for real on a phone or tried building it for native deployment, after all, this was an experiment to see Stitch could replace my complete lack of UI/UX design skills and AntiGravity could implement in a language I dont know about. With more tokens and more time I would probably complete the app and use it