<#
  .SYNOPSIS
  Hawt Koners Tool: A multi-monitor supported hot corners application for Windows.

  .DESCRIPTION
  This script is the base for the Hawt Koners Tool. This program
  allows for each different corner of each different monitor to be
  capable of kicking off different (or the same, if you wish,) macros,
  scripts, and programs.

  .PARAMETER None
  None. There are no parameters accepted to this script.

  .INPUTS
  None. You cannot pipe objects to this script.

  .OUTPUTS
  None. This script does not generate any currently known output.

  .EXAMPLE
  C:\Path\To\hawtKoners.ps1
  # If you run the program this way, you'll need to keep the PowerShell window open while in use.

  .EXAMPLE
  # Another way to run without a window: you'll need to use a command prompt; not a powershell prompt.
  # This is great for Task Scheduler!
  CMD> cmd /c start /min "" powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Path\To\hawtKoners.ps1"

  .LINK
  No links at this writing.
#>

<# TO-DO:

	* Setting / Configuration Tab
		* More PowerShell examples.
	
#>

#######################################
### Initialization
#######################################

#####	Settings Path, Configuration, and Confirmation

# Determining portable Vs. static.
# Whether the app is portable or not, we don't want to keep the Process ID
# file in the portable location. So, let's figure out what exists.
$dataDir = "$($ENV:APPDATA)/HawtKoners"
$wrkDir = ($MyInvocation.MyCommand.Path | Split-Path -Parent)

# Setting environment variables for other files to easily retreive.
Set-Item -Path ENV:hktAppDataPath -Value "$dataDir"
Set-Item -Path ENV:hktPids -Value "$dataDir/process.pid"
Set-Item -Path ENV:hktWrkDir -Value "$wrkDir"
Set-Item -Path ENV:hktAssets -Value "$wrkDir/assets"
Set-Item -Path ENV:mainScript -Value $MyInvocation.MyCommand.Path

# Before we go any further, see if the program is supposedly running right
# now. Clear out any running process and start anew.
. "$($ENV:hktAssets)/reload.ps1"

# Bring in the function to look for a settings file.
. "$($ENV:hktAssets)/functions.ps1"

# Bringing in the function 

# If there is no settings file, then run the Configuration GUI.
If (!(findSettings)) {
	# Start up the GUI Configuration Tool and wait until it's closed.
	Start-Job -FilePath "$($ENV:hktAssets)/cfgGui.ps1"
} Else {
	Set-Item -Path ENV:hktCfgPath -Value "$(findSettings)"
	# Or, if a setting file is found, see if the user wants to open the config tool
	# in its startup.
	$cfgData = Import-Csv -Path "$($ENV:hktCfgPath)/settings.csv"
	$cfg = @{}	
	ForEach ($row in $cfgData) {
		$cfg.Add("$($row.setting)", $row.value)
	}
	
	# If they want it open, then open it.
	If ($cfg.openCfg -eq 1) {
		Start-Job -FilePath "$($ENV:hktAssets)/cfgGui.ps1"
	}
}

# Now, check for the Settings file until there's a settings file somewhere.
# This will run forver, until the computer restarts or someone/something
# closes this powershell instance, or the users attempts to run the script
# again.
While (!(findSettings)) {}

# Once we've broken out of the loop, then we should know where the
# configuration data files are now stored at.
If (!($ENV:hktCfgPath)) {
	Set-Item -Path ENV:hktCfgPath -Value "$(findSettings)"
}

<#
Add-Type -AssemblyName System.Windows.Forms
$title = "Troubleshooting"
$msg = "ENV:hktCfgPath: $($ENV:hktCfgPath)"
$button = [System.Windows.Forms.MessageBoxButtons]::OK
$icon = [System.Windows.Forms.MessageBoxIcon]::Information
[System.Windows.Forms.MessageBox]::Show($msg, $title, $button, $icon)

pause
#>

#####	Functions

# This function runs when the system detects the mouse is in one of the corners.
Function Run-HK-Action {
	# We need which monitor number we're on, and which corner we're in. That data
	#	should've been passed in.
	Param ( [string[]]$Monitor, [string[]]$Corner )

	# Look up the table of actions, and get the data on what we're about to activate.
	$actData = Import-Csv -Path "$($ENV:hktCfgPath)/corners.csv" | Select-Object * | Where-Object {$_.monitorNam -eq $Monitor -and $_.corner -eq $Corner}

	If ($actData.actionType -eq "KeyCombo") {
		# Press some modifier keys down, if they need it.
		If ($actData.modCtrl -eq $true) { [KeySends.KeySend]::KeyDown("LControlKey") }
		If ($actData.modAlt -eq $true) { [KeySends.KeySend]::KeyDown("LMenu") }
		If ($actData.modShift -eq $true) { [KeySends.KeySend]::KeyDown("LShiftKey") }
		If ($actData.modWin -eq $true) { [KeySends.KeySend]::KeyDown("LWin") }

		# Press the last key in the macro down.
		If ($actData.modKey) { [KeySends.KeySend]::KeyDown("$($actData.modKey)") }
		# And lift it up.
		If ($actData.modKey) { [KeySends.KeySend]::KeyUp("$($actData.modKey)") }

		# Now, lift up the modifier keys in backwards order, if they need it.
		If ($actData.modWin -eq $true) { [KeySends.KeySend]::KeyUp("LWin") }
		If ($actData.modShift -eq $true) { [KeySends.KeySend]::KeyUp("LShiftKey") }
		If ($actData.modAlt -eq $true) { [KeySends.KeySend]::KeyUp("LMenu") }
		If ($actData.modCtrl -eq $true) { [KeySends.KeySend]::KeyUp("LControlKey") }
	} ElseIf ($actData.actionType -eq "Command") {
		$cmd = $actData.cmd

		# Kick off what the user sent in.
		Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -ArgumentList "-command `"$cmd`""
	}
}

#####	Setup for Key Presses

# From: https://www.itcodar.com/csharp/sending-windows-key-using-sendkeys.html
$source = @"
using System;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace KeySends
{
	public class KeySend
	{
		[DllImport("user32.dll")]
		public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);
		private const int KEYEVENTF_EXTENDEDKEY = 1;
		private const int KEYEVENTF_KEYUP = 2;
		public static void KeyDown(Keys vKey)
		{
			keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY, 0);
		}
		public static void KeyUp(Keys vKey)
		{
			keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);
		}
	}
}
"@
Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Windows.Forms"

### SysTray Icon --> Configuration Form --> Identifiers
Start-Job -FilePath "$($ENV:hktAssets)/systray.ps1" | Out-Null

#######################################
####	Service Loop
#######################################

# Before running the loop, pertend the mouse is stationed at location X12 x Y12,
#	because I like the number 12.
$prevX = $prevY = 12

# Also, there's no activated corner right now.
$corner = 0
#####	Run Detection Loop
While ($true) {

	# Starting a timer.
	$timer = [Diagnostics.Stopwatch]::StartNew()
	
	# Get a little bit of monitor/display/screen data.
	# $monData = [System.Windows.Forms.Screen]::AllScreens | Sort-Object Bounds
	# Call the Monitor Data function to populate an object for consumption.
	$monData = monDat

	#####	Monitor Data

	# Initialize X and Y coordinate positions for the corners of each screen
	$topLeftX = $topLeftY = $topRightX = $topRightY = $botLeftX = $botLeftY = $botRightX = $botRightY = $null
	
	# Get the configuration settings from the settings file.
	$cfgData = Import-Csv -Path "$(findSettings)/settings.csv"
	$cfg = $cfgData | Group-Object -AsHashTable -Property "setting"
	
	$pxBuffer = [int]$cfg['pxBuffer'].Value
	$restTime = [int]$cfg['restTime'].Value

	While ($timer.elapsed.totalseconds -lt 3) {
		# Save the previous corner before we change it.
        $prevCorner = $corner
		
		# Getting the mouse's current location.
		$mseX = [System.Windows.Forms.Cursor]::Position.X
		$mseY = [System.Windows.Forms.Cursor]::Position.Y

		# No need to execute anything if the mouse hasn't moved......... but! If it
		#	has....
		If (($mseX -ne $prevX -or $mseY -ne $prevY) -and ($mseY -ne $prevY -or $mseX -ne $prevX)) {
			# ....go ahead set the last known mouse position.
			$prevX = $mseX;	$prevY = $mseY

			# Now, for each monitor in existence, determine if the mouse is now in any of
			#	the corners defined in the the Monitor Data section.
			ForEach ($screen in $monData) {
				# For each monitor, determine where their corners are at.
				# Top-Left
				$topLeftX = $screen.Bounds.X
				$topLeftY = $screen.Bounds.Y

				# Top-Right
				$topRightX = ($screen.Bounds.X + $screen.Bounds.Width) - 1
				$topRightY = $screen.Bounds.Y

				# Bottom-Left
				$botLeftX = $screen.Bounds.X
				$botLeftY = ($screen.Bounds.Y + $screen.Bounds.Height) - 1

				# Bottom-Right
				$botRightX = ($screen.Bounds.X + $screen.Bounds.Width) - 1
				$botRightY = ($screen.Bounds.Y + $screen.Bounds.Height) - 1

				# Yes, I went in a Z-pattern, instead of the traditional clockwise-square.
				
				# Checking Top-Left of $i
				If ($mseX -le $topLeftX + $pxBuffer -and $mseX -ge $topLeftX -and $mseY -le $topLeftY + $pxBuffer -and $mseY -ge $topLeftY) { $corner = "topLeft" }
				# Checking Top-Right of $i
				ElseIf ($mseX -ge $topRightX - $pxBuffer -and $mseX -le $topRightX -and $mseY -le $topRightY + $pxBuffer -and $mseY -ge $topRightY) { $corner = "topRight" }
				# Checking Bottom-Left of $i
				ElseIf ($mseX -le $botLeftX + $pxBuffer -and $mseX -ge $botLeftX -and $mseY -ge $botLeftY - $pxBuffer -and $mseY -le $botLeftY) { $corner = "bottomLeft" }
				# Checking Bottom-Right of $i
				ElseIf ($mseX -ge $botRightX - $pxBuffer -and $mseX -le $botRightX -and $mseY -ge $botRightY - $pxBuffer -and $mseY -le $botRightY) { $corner = "bottomRight" }
				# If there is no matching on a corner position, then we'll do nothing.
				Else { $corner = $false }

				# If corner match is found, then go and figure out what to do.
				If ($corner) {
					Break
				}
			}
		}

		# If a corner is/was activated and it's not the same as the previous corner
		If ($corner -and $prevCorner -ne $corner) {
			# Run the action for this corner on this screen.
			# $monNam = $screen.DeviceName -Replace "\W"
			$monNam = $screen.DeviceName
			Run-HK-Action -Monitor $monNam -Corner $corner
			
			# Let's rest a moment to prevent double- and triple-taps.
			Start-Sleep -Milliseconds ($restTime * 1000)
		}
	}
	
	# The time for repeat that loop expired. Stopping timer, then looping back around only to start it up again.
	$timer.stop() 	
}
#>