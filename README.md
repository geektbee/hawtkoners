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

## Run on Logon / Startup
This is still on the to-do list as a checkbox item in the settings. But you can always use any of the three standard methods to manually create a way to have it run on login for now.
* Place a shortcut in `%AppData%\Microsoft\Windows\Start Menu\Programs\Startup` to the `run.cmd` -OR-
* Add a registry entry to the `run.cmd` in the Windows Registry at `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run` -OR-
* Create a task in the Task Scheduler.
  * Triggers Tab:
    *  Begin the task: `At log on`
  * Action tab:
    *  Program/script: `C:\Windows\System32\cmd.exe`
    *  Add arguments: `/c START /min "" powershell.exe -WindowStyle Hidden -ExecutionPolicy ByPass -File "C:\Path\to\HKT Folder\hawtKoners.ps1"`

## Known Bugs and Issues
* Some full-screen applications (games, in my experience) know how to ignore the HKT while it's running. Other full-screen applicaitons don't ignore it and can wind up throwing you for a loop. It seems to be related to Admin Vs. Limited privledges. 
  * Example: Genshin Impact, since it runs in elevated Administrator mode, ignores HKT since HKT runs in limited mode. But Destiny 2 runs in limited mode like HKT defaults. It took me a pretty minute to figure out why my Ghost menu kept activating....
* ISSUE BY-DESIGN: Changing, adding, subtracting, etc monitors/screens, whether physically or in Windows Settings, has the potential to misconfigure HKT settings; you'll more than likely have to re-configure them.
