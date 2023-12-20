# Bring in the Functions for imaging.
. "$($ENV:hktAssets)/functions.ps1"

# Get the PID of the parent; we're going to need it for the icon.
$parentPid = (Import-Csv -Path "$($ENV:hktPids)" | Select-Object * | Where-Object {$_.Process -eq "Parent"}).PID

# Also add in the Process ID for this systray icon
Add-Content -Path "$($ENV:hktPids)" -Force -Confirm:$false -Value "`"$PID`",`"SysTray`""

# Create a Form, of sorts, to serve as a container for the upcoming objects.
$SystrayIcon = New-Object System.Windows.Forms.Form
$SystrayIcon.Size = New-Object System.Drawing.Size(100,20)
$SystrayIcon.Text = "Hawt Korners"
$SystrayIcon.BackColor = "Magenta"
$SystrayIcon.FormBorderStyle = "None"
$SystrayIcon.TransparencyKey = "Magenta"
$SystrayIcon.ShowInTaskbar = $false

#Initialize/configure necessary components
$trayIcon = b64toIco (Get-Content "$($ENV:hktAssets)/icon.b64" -Raw)
$SystrayLauncher = New-Object System.Windows.Forms.NotifyIcon
$SystrayLauncher.Text = "Hawt Koners"
$SystrayLauncher.Icon = $trayIcon
$SystrayLauncher.Visible = $true

# Add the Configure option to the menu.
# Pop-Up Menu on Right-Click
$ContextMenu = New-Object System.Windows.Forms.ContextMenu
$menuCfg = New-Object System.Windows.Forms.MenuItem
$menuCfg.Text = "Configure"
$menuCfg.Add_Click({Start-Job -FilePath "$($ENV:hktAssets)/cfgGui.ps1" | Out-Null})
$ContextMenu.MenuItems.AddRange($menuCfg)

########
#	"Exit" Menu Options
Function Exit-Option {
	param([string]$Text)
	$ExitItem = New-Object System.Windows.Forms.MenuItem
	$ExitItem.Text = $Text
	$ExitItem.Add_Click({

		# Create an array of which all processes to later.
		$arrPids = @()
		
		# We're about to close everything. There's a good order to do this. First this Identifiers, if any. then the Configuration form, if any. But the systry launcher last, fo sho.
		$identifyPids = (Import-Csv -Path "$($ENV:hktPids)" | Select-Object * | Where-Object {$_.Process -eq "Identify"}).PID
		$cfgFormPid = (Import-Csv -Path "$($ENV:hktPids)" | Select-Object * | Where-Object {$_.Process -eq "ConfigForm"}).PID
		$systrayPid = (Import-Csv -Path "$($ENV:hktPids)" | Select-Object * | Where-Object {$_.Process -eq "SysTray"}).PID
		$parentPid = (Import-Csv -Path "$($ENV:hktPids)" | Select-Object * | Where-Object {$_.Process -eq "Parent"}).PID

		If ($identifyPids) {
			ForEach ($proc in $identifyPids) {
				# Stopping this one.
				#Stop-Process -ID $proc -Force
				$arrPids += $proc
				
				# Sleep a bit to allow the system to catch up.
				#Start-Sleep -Milliseconds 500

				# Remove that PID from the file.
				(Get-Content "$($ENV:hktPids)" | Where-Object {$_ -notlike "`"$proc`"*"}) | Set-Content "$($ENV:hktPids)"
			}
		}

		If ($cfgFormPid) {
			#Stop-Process $cfgFormPid -Force
			$arrPids += $cfgFormPid
			#Start-Sleep -Milliseconds 500
			(Get-Content "$($ENV:hktPids)" | Where-Object {$_ -notlike "*`"ConfigForm`""}) | Set-Content "$($ENV:hktPids)"
		}

		If ($systrayPid) {
			#Start-Sleep -Milliseconds 500
			$SystrayIcon.ShowInTaskbar = $false
			$SystrayLauncher.Visible = $false
			$SystrayIcon.Close()
			#Stop-Process $systrayPid -Force
			$arrPids += $systrayPid
			(Get-Content "$($ENV:hktPids)" | Where-Object {$_ -notlike "*`"SysTray`""}) | Set-Content "$($ENV:hktPids)"
		}

		# Removing the parent process id from status manager.
		(Get-Content "$($ENV:hktPids)" | Where-Object {$_ -notlike "*`"Parent`""}) | Set-Content "$($ENV:hktPids)"

		#Handle any hung processes from original program.
		#Stop-Process $parentPid -Force
		$arrPids += $parentPid
		Stop-Process $arrPids -Force
	}) # End Add_Click feature

	# This magically places the options on the menu.
	$ExitItem
} # End Exit/Reload option.

# A purdy seperator
$ContextMenu.MenuItems.Add("-")

$exitApp = Exit-Option -Text "Exit"
$ContextMenu.MenuItems.AddRange($exitApp)

#Add all the components to the menu.
$SystrayLauncher.ContextMenu = $ContextMenu

$SystrayLauncher.Add_Click({
	If ($_.Button -eq [Windows.Forms.MouseButtons]::Left) {
		Start-Job -FilePath "$($ENV:hktAssets)/cfgGui.ps1" | Out-Null
	}
})

# See if this is the first time running the program or not. If it is, then show the configuration screen(s)
# Get the configuration settings from the settings file.
$cfgData = Import-Csv -Path "$($ENV:hktSettings)"
$cfg = $cfgData | Group-Object -AsHashTable -Property "setting"

If ($cfg['openCfg'].Value -eq "True") { ConfigApp }

#Launch the SysTray Icon.
$SystrayIcon.ShowDialog()