# HKT: Hawt Koners Tool
## Description
This Windows program was born out of experiencing the feature on Linux many years ago. Later, it made its way to the Apple/Mac interface. I thought it a novel concept and thought it'd be nice to have it on Windows, so I got on Google and starting searching for Hot Corner apps for Windows. I found quite a few; but none would work the way I thought they should with two and/or more monitors. Most apps would only work on the primary monitor only. I think I found one app that would work on all monitors, but all respective corners would perform the same action. I was looking for different actions for each respective corner. After all, I have three monitors, that's 12 programmable corners, in my mind, at least.

I gave up looking for a while. Eventually, I thought to try to look again. Certaintly, after all these years, someone was able to make a Windows hot corner app that knows how to handle the additional corners.... or so I thought.

Still, nope.

My day job is working with applicaitons and services like Active Directory, AzureAD, and Microsoft 365. So, I thought I was proficent enough in PowerShell by this point to making an app myself.

So, using Notepad++, my PowerShell knowledge, DuckDuckGo, Google, and a PowerShell terminal, I set out to learning PowerShell GUI Forms....

"Hawt Koners Tool" is the result.

~geektbee

## Installation
There's not really an installation. Just extract the files to somewhere you can find them. We recommend `C:\Program Files\HKT\` or `C:\Program Files\HawtKoners\`. But if you want the Portable feature, you'll need to place them in a folder where your account has Read & Write permission, like your DropBox, Google Drive, OneDrive, OwnCloud, Syncthing, flash drive, or whatever you chose for your portable service. 

## Running
If you try to run the initial PS1 script willy-nilly, a terminal/command window will open. Closing it can cause errors and such. Therefore, we recommend running the file using the `run.cmd` that's provided.

## Screen Options and Configurations
Corner layout design: Each configuration for each corner has three options:
* Disabled
* Keyboard Hotkey
* PowerShell Command.
Each option that's not in use becomes greyed-out until that radio button is selected. I found that helps in times of troubleshooting.

![image](https://github.com/geektbee/hawtkoners/assets/16610859/de8271ac-e802-49dd-92f8-2753e8fbd70f)

The "Identify" button in action, shows which Tab goes with which display. Does not conforms to what's in Windows Settings, because I couldn't figure out how they did that.

![image](https://github.com/geektbee/hawtkoners/assets/16610859/664e943a-9b77-450e-8cab-91b99fcb4de5)

The "Settings" tab: Mostly just a place for some little helpers and conveniences. 

![image](https://github.com/geektbee/hawtkoners/assets/16610859/04c912b6-d11c-4537-b256-ae93bcbc0df1)

## Created and Tested On and For:
* Windows 11 Pro x64

## Known Bugs and Issues
* Some full-screen applications (games, in my experience) know how to ignore the HKT while it's running. Other full-screen applicaitons don't ignore it and can wind up throwing you for a loop. It seems to be related to Admin Vs. Limited privledges. 
  * Example: Genshin Impact, since it runs in elevated Administrator mode, ignores HKT since HKT runs in limited mode. But Destiny 2 runs in limited mode like HKT defaults. It took me a pretty minute to figure out why my Ghost menu kept activating....
* ISSUE BY-DESIGN: Changing, adding, subtracting, etc monitors/screens, whether physically or in Windows Settings, has the potential to misconfigure HKT settings; you'll more than likely have to re-configure them if you add, change, and/or remove screens.
