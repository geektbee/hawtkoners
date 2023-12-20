# See if there's already a form running.
$ConfigFormPID = (Import-Csv -Path "$($ENV:hktPids)" | Select-Object * | Where-Object {$_.Process -eq "ConfigForm"}).PID

# If there's no other config form already, then we can show it.
If (!$ConfigFormPID) {
	# Bring in the Functions for imaging.
	. "$($ENV:hktAssets)/functions.ps1"

	# Tell the PID file that were're running now.
	Add-Content -Path "$($ENV:hktPids)" -Force -Confirm:$false -Value "`"$PID`",`"ConfigForm`""

	[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	# $monData = [System.Windows.Forms.Screen]::AllScreens | Sort-Object Bounds
	# Call the Monitor Data function to populate an object for consumption.
	$monData = monDat

	# This might be the first run ever, so, compensate.
	If (!($ENV:hktCfgPath)) {
		# Set the defaults for the other Settings and Configurations.
		$cfg = @{}
		$cfg.Add('pxBuffer', 4)
		$cfg.Add('restTime', 1)
		$cfg.Add('idTimer', 7)
		$cfg.Add('openCfg', 0)


		# Since there's no config path, we'll need to re-create what Import-Csv would otherwise do.
		$cornerData = @()
		
		ForEach ($screen in $monData) {
			# $monNam = $screen.DeviceName -Replace "\W"
			$monNam = $screen.DeviceName
			"topLeft", "topRight", "bottomLeft", "bottomRight" | % { 
				$cornerData += @([PSCustomObject]@{
					monitorNam = $monNam
					corner = $_
					actionType = "Disabled"
					modCtrl = "False"
					modAlt = "False"
					modShift = "False"
					modWin = "False"
					modKey = ""
					cmd = ""
				})
			}
		}
	} Else {
		# The configuration does seem to exist, so settings should exist.
		# Get those values then.
		$cfgData = Import-Csv -Path "$($ENV:hktCfgPath)/settings.csv"
		$cfg = @{}
		
		ForEach ($row in $cfgData) {
			$cfg.Add("$($row.setting)", $row.value)
		}

		# Import the data file that holds the corner data.
		$cornerData = Import-Csv -Path "$($ENV:hktCfgPath)/corners.csv"
	}

	# Go ahead and get the current data as it currently stands.

	#####	Monitor Data
	# Gathering the monitor data
	Add-Type -AssemblyName System.Windows.Forms

	#####	Acceptible Keyboard Shortcut Keys
	$keyList = @()

	$keyList += 65..90 | ForEach-Object{[char]$_}	#	Alphabet A - Z
	$keyList += 0..9					#	Numbers 0 - 9
	$keyList += 39 | ForEach-Object{[char]$_}		#	Special Char: '
	$keyList += 42..47 | ForEach-Object{[char]$_}	#	Special Chars: * + , - . /
	$keyList += 59 | ForEach-Object{[char]$_}		#	Special Char: ;
	$keyList += 61 | ForEach-Object{[char]$_}		#	Special Char: =
	$keyList += 91..93 | ForEach-Object{[char]$_}	#	Special Chars: [ ! ]
	$keyList += 96 | ForEach-Object{[char]$_}		#	Special Char: `

	# Named Keys
	$keyList += "Escape", "ESC"
	$keyList += "Tab", "CapsLock"
	$keyList += "BackSpace", "BS"
	$keyList += "Enter", "Return"
	$keyList += "ScrollLock", "Break"
	$keyList += "Insert", "INS", "Home", "Delete", "DEL", "End", "PgUp", "PgDown"
	$keyList += "Up", "Down", "Left", "Right"
	$keyList += "NumLock"

	# Function keys
	For ($i = 1; $i -le 15; $i++) { $keyList += "F$i" }

	#######################################
	### Form
	#######################################

	# Main Form Dimensions
	$width	= 600
	$height	= 470

	# Some calculations. Each tab will have 4 "corners" to represent the four
	#	corners of a Display. These calculations attempt to make life eaiser if we
	#	decide to add more line items.
	$xHalf = ($width / 2) - 20
	$yHalf = ($height / 2) - 50

	$xGrpboxSize = $xHalf - 10
	$yGrpboxSize = $yHalf - 10

	# Main Form Setup
	$trayIcon = b64toIco (Get-Content "$($ENV:hktAssets)/icon.b64" -Raw)
	$cfgForm = New-Object System.Windows.Forms.Form
	$cfgForm.Text = "Hawt Koners Tool Configuration"
	$cfgForm.FormBorderStyle = "FixedSingle"
	$cfgForm.Icon = $trayIcon
	$cfgForm.TaskbarItemInfo.Overlay = $trayIcon
	$cfgForm.Width = $width
	$cfgForm.Height = $height
	$cfgForm.MaximizeBox = $false
	$cfgForm.MinimizeBox = $false
	$cfgForm.ShowInTaskbar = $false

	# Tab Control
	$FormTabControl = New-Object System.Windows.Forms.TabControl
	$FormTabControl.Size = New-Object System.Drawing.Size(($width - 36),($height - 80))
	$FormTabControl.Location = "10,0"

	# Add the Tab control to the Main Form.
	$cfgForm.Controls.Add($FormTabControl)

	# Before setting up the content within the tab(s), initialize some arrays.
	$tab = $rBtnDisable = $rBtnKeyCombo = $rBtnCmd = $cBoxMCtrl = $cBoxMAlt = $cBoxMShift = $cBoxMWin = $ddKey = $cmdPath = $groupBox = @{}


	# We're going to have one tab for each monitor that was found. Each tab will
	#	consist of visually similar controls, but we need each control to have a
	#	different identifier so we can properly update the settings file when it's
	#	time.
	$monNum = 0
	ForEach ($screen in $monData) {
		$monNum++

		# Monitor ID is what PowerShell knows the monitor as, but the common User
		#	probably thinks computers start counting at 1, so we'll continue that
		#	illusion by referring to it correctly behind the scenes but not to the user's
		#	eyes.
		# $monID = $screen.DeviceName -Replace "\W"
		$monID = $screen.DeviceName

		############
		#	Monitor/Display Tab(s)
		############
		# Creating the Tab Data
		$tab[$monID] = New-Object System.Windows.Forms.Tabpage
		$tab[$monID].Text = "Display $monNum"
		$tab[$monID].Name = "Display$monID"
		$tab[$monID].DataBindings.DefaultDataSourceUpdateMode = 0
		$tab[$monID].UseVisualStyleBackColor = $True

		# Drawing the tab now.
		$FormTabControl.Controls.Add($tab[$monID])

		# For the four corners, we'll want to visually layout a sensible grid. So, for
		#	each corner:
		"topLeft", "topRight", "bottomLeft", "bottomRight" | % {
			$cornerLoc = $_
			
			# Determine which corner we looking at doing now. remember the Z-pattern, not
			#	the clockwise-pattern.
			Switch($cornerLoc) {
				"topLeft"		{ $xLoc = 004;	$yLoc = 004;	$locName = "Top-Left Corner"		}
				"topRight"		{ $xLoc = $xHalf;	$yLoc = 004;	$locName = "Top-Right Corner"	}
				"bottomLeft"	{ $xLoc = 004;	$yLoc = $yHalf;	$locName = "Bottom-Left Corner"		}
				"bottomRight"	{ $xLoc = $xHalf;	$yLoc = $yHalf;	$locName = "Bottom-Right Corner"}
			}

			# Get the data for this corner from settings data.
			$thisCorner = $cornerData | Select-Object * | Where-Object {$_.monitorNam -eq $monID -and $_.corner -eq $cornerLoc}

			# For each control to be uniquely named, set this as a suffix on each control.
			$id = "$monID$cornerLoc"
			$fieldId = "obj$id"
			$groupId = "grp$id"

			############
			#	Groups
			############
			# Drawing a Group box, to help with all the visualizations.
			# Comments for most controls after this one will be very similar, so the
			#	comments here can probably also apply to most subsequent controls.
			# Setting up the candy-eye.
			$groupBox[$groupId] = New-Object System.Windows.Forms.GroupBox
			# Assigning a location, in relation to the tab at this point, because that's what we'll it to in a few ticks. (width, height)
			$groupBox[$groupId].Location = New-Object System.Drawing.Size($xLoc,$yLoc)
			# How big the control ought to be. We want them all the same size so things look nice and orderly. (width, height)
			$groupBox[$groupId].Size = New-Object System.Drawing.Size($xGrpboxSize,$yGrpboxSize)
			# Give the control a name that the user can read.
			$groupBox[$groupId].Text = "$locName"
			# And finally, slap the control on the tab.
			$tab[$monID].Controls.Add($groupBox[$groupId])

			# Y-position line can help with the next line. Each time we want to move to next
			#	line, just add 20, 25, or 30; w/e seems reasonible for candy.
			$lineY = 0		# Starter position.

			############
			#	Radio Button: Disabled
			############
			$lineY = $lineY + 20
			$rBtnDisable[$fieldId] = New-Object System.Windows.Forms.RadioButton
			$rBtnDisable[$fieldId].Location = New-Object System.Drawing.Point(15,$lineY)
			$rBtnDisable[$fieldId].Size = New-Object System.Drawing.Size(200,20)
			$rBtnDisable[$fieldId].Text = "Disabled"
			$rBtnDisable[$fieldId].Name = "rDisable_$fieldId"
			# Selecting this radio button if the settings say to do so.
			$rBtnDisable[$fieldId].Checked = If ($thisCorner.actionType -eq "Disabled") { $true } Else { $false }
			# If the user ever changes to this selection, then disable the others.
			$rBtnDisable[$fieldId].Add_Click({
				ForEach ($chkScr in $monData) {
					$chkMonID = $chkScr.DeviceName
					
					"topLeft", "topRight", "bottomLeft", "bottomRight" | % {
						$chkCornerLoc = $_
						
						$chkId = "$chkMonID$chkCornerLoc"
						$chkFieldId = "obj$chkId"
						$chkGroupId = "grp$chkId"
						
						$chkRKeyCombo = ($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "rDisable_$chkFieldId"} ).Checked
						If ($chkRKeyCombo) {
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "tCmd_$chkFieldId"}).Enabled = $false
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "cModCtrl_$chkFieldId"}).Enabled = $false
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "cModAlt_$chkFieldId"}).Enabled = $false
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "cModShift_$chkFieldId"}).Enabled = $false
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "cModWin_$chkFieldId"}).Enabled = $false
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "ddKey_$chkFieldId"}).Enabled = $false
						}
					}
				}
			})

			# And finally, slap the control on the Group Box.
			$groupBox[$groupId].Controls.Add($rBtnDisable[$fieldId])

			############
			#	Radio Button: Keyboard Shortcut
			############
			$lineY = $lineY + 25
			$rBtnKeyCombo[$fieldId] = New-Object System.Windows.Forms.RadioButton
			$rBtnKeyCombo[$fieldId].Location = New-Object System.Drawing.Point(15,$lineY)
			$rBtnKeyCombo[$fieldId].Size = New-Object System.Drawing.Size(200,20)
			$rBtnKeyCombo[$fieldId].Text = "Keyboard Hotkey"
			$rBtnKeyCombo[$fieldId].Name = "rKeyCombo_$fieldId"
			# Selecting this radio button if the settings say to do so.
			$rBtnKeyCombo[$fieldId].Checked = If ($thisCorner.actionType -eq "KeyCombo") { $true } Else { $false }
			$rBtnKeyCombo[$fieldId].Add_Click({
				ForEach ($chkScr in $monData) {
					$chkMonID = $chkScr.DeviceName
					
					"topLeft", "topRight", "bottomLeft", "bottomRight" | % {
						$chkCornerLoc = $_
						
						$chkId = "$chkMonID$chkCornerLoc"
						$chkFieldId = "obj$chkId"
						$chkGroupId = "grp$chkId"
						
						$chkRKeyCombo = ($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "rKeyCombo_$chkFieldId"} ).Checked
						If ($chkRKeyCombo) {
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "tCmd_$chkFieldId"}).Enabled = $false
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "cModCtrl_$chkFieldId"}).Enabled = $true
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "cModAlt_$chkFieldId"}).Enabled = $true
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "cModShift_$chkFieldId"}).Enabled = $true
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "cModWin_$chkFieldId"}).Enabled = $true
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "ddKey_$chkFieldId"}).Enabled = $true
						}
					}
				}
#				enable_KeyComboOpts
#				disable_CmdOpts $groupBox[$groupId] $fieldId
			})
			# And finally, slap the control on the Group Box.
			$groupBox[$groupId].Controls.Add($rBtnKeyCombo[$fieldId])

			########
			#### Checkbox Options for Keyboard Modifers
			########
			$lineY = $lineY + 20

			#### Control Key
			$cBoxMCtrl[$fieldId] = New-Object System.Windows.Forms.CheckBox
			$cBoxMCtrl[$fieldId].Location = New-Object System.Drawing.Point(50,$lineY)
			$cBoxMCtrl[$fieldId].Size = New-Object System.Drawing.Size(50,20)
			$cBoxMCtrl[$fieldId].Text = "Ctrl"
			$cBoxMCtrl[$fieldId].Name = "cModCtrl_$fieldId"
			$cBoxMCtrl[$fieldId].Checked = If ($thisCorner.modCtrl -eq "True") { $true } Else { $false }
			$cBoxMCtrl[$fieldId].Enabled = If ($thisCorner.actionType -eq "KeyCombo") { $true } Else { $false }
			$groupBox[$groupId].Controls.Add($cBoxMCtrl[$fieldId])

			#### Alternate Key
			$cBoxMAlt[$fieldId] = New-Object System.Windows.Forms.CheckBox
			$cBoxMAlt[$fieldId].Location = New-Object System.Drawing.Point(100,$lineY)
			$cBoxMAlt[$fieldId].Size = New-Object System.Drawing.Size(50,20)
			$cBoxMAlt[$fieldId].Text = "Alt"
			$cBoxMAlt[$fieldId].Name = "cModAlt_$fieldId"
			$cBoxMAlt[$fieldId].Checked = If ($thisCorner.modAlt -eq "True") { $true } Else { $false }
			$cBoxMAlt[$fieldId].Enabled = If ($thisCorner.actionType -eq "KeyCombo") { $true } Else { $false }
			$groupBox[$groupId].Controls.Add($cBoxMAlt[$fieldId])

			#### Shift Key
			$cBoxMShift[$fieldId] = New-Object System.Windows.Forms.CheckBox
			$cBoxMShift[$fieldId].Location = New-Object System.Drawing.Point(150,$lineY)
			$cBoxMShift[$fieldId].Size = New-Object System.Drawing.Size(50,20)
			$cBoxMShift[$fieldId].Text = "Shift"
			$cBoxMShift[$fieldId].Name = "cModShift_$fieldId"
			$cBoxMShift[$fieldId].Checked = If ($thisCorner.modShift -eq "True") { $true } Else { $false }
			$cBoxMShift[$fieldId].Enabled = If ($thisCorner.actionType -eq "KeyCombo") { $true } Else { $false }
			$groupBox[$groupId].Controls.Add($cBoxMShift[$fieldId])

			#### Windows Key
			$cBoxMWin[$fieldId] = New-Object System.Windows.Forms.CheckBox
			$cBoxMWin[$fieldId].Location = New-Object System.Drawing.Point(200,$lineY)
			$cBoxMWin[$fieldId].Size = New-Object System.Drawing.Size(50,20)
			$cBoxMWin[$fieldId].Text = "Win"
			$cBoxMWin[$fieldId].Name = "cModWin_$fieldId"
			$cBoxMWin[$fieldId].Checked = If ($thisCorner.modWin -eq "True") { $true } Else { $false }
			$cBoxMWin[$fieldId].Enabled = If ($thisCorner.actionType -eq "KeyCombo") { $true } Else { $false }
			$groupBox[$groupId].Controls.Add($cBoxMWin[$fieldId])

			#### Keyboard Shortcut Key Label
			$lineY = $lineY + 25
			$keyLabel = New-Object System.Windows.Forms.Label
			$keyLabel.Location = New-Object System.Drawing.Point(50,$lineY)
			$keyLabel.Size = New-Object System.Drawing.Size(30,20)
			$keyLabel.Text = "Key:"
			$groupBox[$groupId].Controls.Add($keyLabel)

			#### Keyboard Shortcut Key Drop-Down box
			$ddKey[$fieldId] = New-Object System.Windows.Forms.ComboBox
			$ddKey[$fieldId].Location = New-Object System.Drawing.Point(80,$lineY)
			$ddKey[$fieldId].Size = New-Object System.Drawing.Size(150,20)
			$ddKey[$fieldId].Name = "ddKey_$fieldId"
			$ddKey[$fieldId].DropDownHeight = 200
			$ddKey[$fieldId].DropDownStyle = "DropDownList"
			$ddKey[$fieldId].Enabled = If ($thisCorner.actionType -eq "KeyCombo") { $true } Else { $false }
			$groupBox[$groupId].Controls.Add($ddKey[$fieldId])

			# Add a Blank item as the first item in the drop-down box.
			$ddKey[$fieldId].Items.Add("") | Out-Null
			# Now, add all of the approved keyboard shortcut keys to the list.
			ForEach ($hKey in $keyList) { $ddKey[$fieldId].Items.Add($hKey) | Out-Null }
			# If the settings file has a value for the key, then set the selected item in
			#	the box to be that.
			If ($thisCorner.modKey) { $ddKey[$fieldId].SelectedIndex = $ddKey[$fieldId].FindStringExact("$($thisCorner.modKey)") }

			############
			#	Radio Button: Command option
			############
			$lineY = $lineY + 30
			$rBtnCmd[$fieldId] = New-Object System.Windows.Forms.RadioButton
			$rBtnCmd[$fieldId].Location = New-Object System.Drawing.Point(15,$lineY)
			$rBtnCmd[$fieldId].Size = New-Object System.Drawing.Size(180,20)
			$rBtnCmd[$fieldId].Text = "Powershell Command: "
			$rBtnCmd[$fieldId].Name = "rCmd_$fieldId"
			$rBtnCmd[$fieldId].Checked = If ($thisCorner.actionType -eq "Command") { $true } Else { $false }
			$rBtnCmd[$fieldId].Add_Click({
				ForEach ($chkScr in $monData) {
					$chkMonID = $chkScr.DeviceName
					
					"topLeft", "topRight", "bottomLeft", "bottomRight" | % {
						$chkCornerLoc = $_
						
						$chkId = "$chkMonID$chkCornerLoc"
						$chkFieldId = "obj$chkId"
						$chkGroupId = "grp$chkId"
						
						$chkRKeyCombo = ($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "rCmd_$chkFieldId"} ).Checked
						If ($chkRKeyCombo) {
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "tCmd_$chkFieldId"}).Enabled = $true
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "cModCtrl_$chkFieldId"}).Enabled = $false
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "cModAlt_$chkFieldId"}).Enabled = $false
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "cModShift_$chkFieldId"}).Enabled = $false
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "cModWin_$chkFieldId"}).Enabled = $false
							($groupBox[$chkGroupId].Controls | Where-Object { $_.Name -eq "ddKey_$chkFieldId"}).Enabled = $false
						}
					}
				}
#				disable_KeyComboOpts
#				enable_CmdOpts $groupBox[$groupId] $fieldId
			})
			$groupBox[$groupId].Controls.Add($rBtnCmd[$fieldId])

			#### Input Text Box for program/command
			$lineY = $lineY + 20
			$cmdPath[$fieldId] = New-Object System.Windows.Forms.TextBox
			$cmdPath[$fieldId].Location = New-Object System.Drawing.Point(50,$lineY)
			$cmdPath[$fieldId].Size = New-Object System.Drawing.Size(180,20)
			$cmdPath[$fieldId].Text = "$($thisCorner.cmd)"
			$cmdPath[$fieldId].Name = "tCmd_$fieldId"
			$cmdPath[$fieldId].Enabled = If ($thisCorner.actionType -eq "Command") { $true } Else { $false }
			$groupBox[$groupId].Controls.Add($cmdPath[$fieldId])
		} # All done with this group.
	} # All done with this Display.

	############
	# "Settings and Preferences" Tab
	############

	# Creating the Tab Data
	$tabAbout = New-Object System.Windows.Forms.Tabpage
	$tabAbout.Text = "Settings & Support"
	$tabAbout.Name = "AboutTab"
	$tabAbout.DataBindings.DefaultDataSourceUpdateMode = 0
	$tabAbout.UseVisualStyleBackColor = $True

	# Drawing the tab now.
	$FormTabControl.Controls.Add($tabAbout)

	#### Settings Group Box
	$settingsBox = New-Object System.Windows.Forms.GroupBox
	$settingsBox.Location = New-Object System.Drawing.Size(4,10)
	$settingsBox.Size = New-Object System.Drawing.Size(($width - 350),180)
	$settingsBox.Text = "Settings and Preferences"
	$tabAbout.Controls.Add($settingsBox)

	#### Pixel Buffer Value
	$pxBuff = New-Object System.Windows.Forms.NumericUpDown
	$pxBuff.Location = New-Object System.Drawing.Point(8,22)
	$pxBuff.Size = New-Object System.Drawing.Size(50,14)
	$pxBuff.Name = "setPxBuffer"
	$pxBuff.Minimum = 0
	$pxBuff.Maximum = 600
	$pxBuff.Value = $cfg.pxBuffer
	$settingsBox.Controls.Add($pxBuff)

	#### Pixel Buffer label
	$pxBuffLabel = New-Object System.Windows.Forms.Label
	$pxBuffLabel.Location = New-Object System.Drawing.Point(60,26)
	$pxBuffLabel.Size = New-Object System.Drawing.Size(100,14)
	$pxBuffLabel.Text = "px Corner Buffers"
	$settingsBox.Controls.Add($pxBuffLabel)

	#### Rest Time Value
	$restTime = New-Object System.Windows.Forms.NumericUpDown
	$restTime.Location = New-Object System.Drawing.Point(8,50)
	$restTime.Size = New-Object System.Drawing.Size(50,14)
	$restTime.Name = "setRestTime"
	$restTime.Minimum = 0
	$restTime.Maximum = 600
	$restTime.DecimalPlaces  = 1
	$restTime.Increment = .1
	$restTime.Value = $cfg.restTime
	$settingsBox.Controls.Add($restTime)

	#### Rest Time Label
	$waitTime = New-Object System.Windows.Forms.Label
	$waitTime.Location = New-Object System.Drawing.Point(60,54)
	$waitTime.Size = New-Object System.Drawing.Size(130,14)
	$waitTime.Text = "second(s) Rest Time"
	$settingsBox.Controls.Add($waitTime)

	#### Identifer Timer Value
	$idTime = New-Object System.Windows.Forms.NumericUpDown
	$idTime.Location = New-Object System.Drawing.Point(8,78)
	$idTime.Size = New-Object System.Drawing.Size(50,14)
	$idTime.Name = "setIdTimer"
	$idTime.Minimum = 0
	$idTime.Maximum = 600
	$idTime.DecimalPlaces  = 1
	$idTime.Increment = .1
	$idTime.Value = $cfg.idTimer
	$settingsBox.Controls.Add($idTime)

	#### Identifer Timer Label
	$idTimeLabel = New-Object System.Windows.Forms.Label
	$idTimeLabel.Location = New-Object System.Drawing.Point(60,82)
	$idTimeLabel.Size = New-Object System.Drawing.Size(180,14)
	$idTimeLabel.Text = "second(s) Identifier Timer"
	$settingsBox.Controls.Add($idTimeLabel)

	#### Open Cfg on Start Checkbox
	$cfgStart = New-Object System.Windows.Forms.CheckBox
	$cfgStart.Location = New-Object System.Drawing.Point(12,106)
	$cfgStart.Size = New-Object System.Drawing.Size(230,18)
	$cfgStart.Text = "Open this Config Tool when app starts"
	$cfgStart.Name = "setOpenCfg"
	$cfgStart.Checked = If ($cfg.openCfg -eq 1) { $true } Else { $false }
	$settingsBox.Controls.Add($cfgStart)

	#### Portable Config Checkbox
	# We actually don't want to show this section if the user can't write
	# anything to the program's folder in the first place. So, run a test
	# first.
	$testFil = "$($ENV:hktWrkDir)/chWritePerm.test"
	New-Item -Path "$testFil" -Force -Confirm:$false -ErrorAction SilentlyContinue
	If (Test-Path "$testFil") {
		Remove-Item -Path "$testFil" -Force -Confirm:$false

		$cfgPortable = New-Object System.Windows.Forms.CheckBox
		$cfgPortable.Location = New-Object System.Drawing.Point(12,128)
		$cfgPortable.Size = New-Object System.Drawing.Size(230,18)
		$cfgPortable.Text = "Portable Configuration"
		$cfgPortable.Name = "setPortable"
		$cfgPortable.Checked = If (Test-Path "$($ENV:hktWrkDir)/config/settings.csv") { $true } Else { $false }
		$settingsBox.Controls.Add($cfgPortable)
	} # Else? :: Don't show that.

	#### Click Apply Label
	$applyLabel = New-Object System.Windows.Forms.Label
	$applyLabel.Location = New-Object System.Drawing.Point(4,160)
	$applyLabel.Size = New-Object System.Drawing.Size(240,14)
	$applyLabel.Text = "Click `"Apply`" or `"OK`" to apply changes"
	$settingsBox.Controls.Add($applyLabel)

	#### Examples Group Box
	$exampleBox = New-Object System.Windows.Forms.GroupBox
	$exampleBox.Location = New-Object System.Drawing.Size(260,10)
	$exampleBox.Size = New-Object System.Drawing.Size(($width - 312),180)
	$exampleBox.Text = "Information and Guides"
	$tabAbout.Controls.Add($exampleBox)

	#### License Content Text
	$exampleText = New-Object System.Windows.Forms.Textbox
	$exampleText.Location = New-Object System.Drawing.Point(4,16)
	$exampleText.Size = New-Object System.Drawing.Size(($width - 322),160)
	$exampleText.ScrollBars = "Both"
	$exampleText.MultiLine = $True
	$exampleText.ReadOnly = $True
	$exampleText.WordWrap = $False
	$exampleText.Text = (Get-Content "$($ENV:hktAssets)/infoGuides.txt" -Raw)
	$exampleBox.Controls.Add($exampleText)

	#### License Label
	$licLabel = New-Object System.Windows.Forms.Label
	$licLabel.Location = New-Object System.Drawing.Point((($width / 2) - 110),195)
	$licLabel.Size = New-Object System.Drawing.Size(170,14)
	$licLabel.Text = "GNU General Public License"
	$licLabel.TextAlign = "MiddleCenter"
	$tabAbout.Controls.Add($licLabel)

	#### License Group Box
	$licBox = New-Object System.Windows.Forms.GroupBox
	$licBox.Location = New-Object System.Drawing.Size(4,195)
	$licBox.Size = New-Object System.Drawing.Size(($width - 56),100)
	$tabAbout.Controls.Add($licBox)

	#### License Content Text
	$license = New-Object System.Windows.Forms.Textbox
	$license.Location = New-Object System.Drawing.Point(10,16)
	$license.Size = New-Object System.Drawing.Size(($width - 76),75)
	$license.ScrollBars = "Vertical"
	$license.MultiLine = $True
	$license.ReadOnly = $True
	$license.WordWrap = $True
	$license.Text = (Get-Content "$($ENV:hktAssets)/license.txt" -Raw)
	$licBox.Controls.Add($license)

	#### Donation Group Box
	$donateBox = New-Object System.Windows.Forms.GroupBox
	$donateBox.Location = New-Object System.Drawing.Size(4,300)
	$donateBox.Size = New-Object System.Drawing.Size(($width - 350),60)
	$donateBox.Text = "Donation Option"
	$tabAbout.Controls.Add($donateBox)

	#### PayPal Donate Link Image
	$img = b64toImg (Get-Content "$($ENV:hktAssets)/paypal.b64" -Raw)
	$paypalImg = New-Object Windows.Forms.PictureBox
	$paypalImg.Location = New-Object System.Drawing.Size(40,20)
	$paypalImg.Size = New-Object System.Drawing.Size(98,30)
	$paypalImg.Image = $img
	$paypalImg.Add_Click({[System.Diagnostics.Process]::Start("https://www.paypal.com/donate/?hosted_button_id=2VVQGL5BHU46W")})
	$donateBox.Controls.Add($paypalImg)

	#### Paypal QR Code
	$paypalQrLink = New-Object System.Windows.Forms.LinkLabel
	$paypalQrLink.Location = New-Object System.Drawing.Size(140,30)
	$paypalQrLink.Size = New-Object System.Drawing.Size(60,12)
	$paypalQrLink.Text = "QR Code"
	$paypalQrLink.LinkColor = "BLUE"
	$paypalQrLink.ActiveLinkColor = "RED"
	$paypalQrLink.Add_Click({
		#### PayPal QR Code Popup Form
		$paypalQrForm = New-Object System.Windows.Forms.Form -Property @{TopMost=$true}
		$paypalQrForm.Text = "PayPal Donation QR Code"
		$paypalQrForm.Name = "PayPalQRCode"
		$paypalQrForm.BackColor = "#FFFFFF"
		$paypalQrForm.FormBorderStyle = "FixedSingle"
		$paypalQrForm.StartPosition = "Center"
		$paypalQrForm.Width = 220
		$paypalQrForm.Height = 240
		$paypalQrForm.MaximizeBox = $false
		$paypalQrForm.MinimizeBox = $false
		$paypalQrForm.ShowInTaskbar = $false
		$paypalQrForm.Icon = $trayIcon

		#### PayPal QR Code Image
		$img = b64toImg (Get-Content "$($ENV:hktAssets)/paypalQR.b64" -Raw)
		$paypalQrImg = New-Object Windows.Forms.PictureBox
		$paypalQrImg.Location = New-Object System.Drawing.Size(4,4)
		$paypalQrImg.Size = New-Object System.Drawing.Size(192,192)
		$paypalQrImg.Image = $img
		$paypalQrForm.Controls.Add($paypalQrImg)

		#### Show it.
		$paypalQrForm.ShowDialog()
	})
	$donateBox.Controls.Add($paypalQrLink)

	#### Credits Group Box
	$creditsBox = New-Object System.Windows.Forms.GroupBox
	$creditsBox.Location = New-Object System.Drawing.Size(260,300)
	$creditsBox.Size = New-Object System.Drawing.Size(($width - 312),60)
	$creditsBox.Text = "Credits / Source"
	$tabAbout.Controls.Add($creditsBox)

	#### Heading label
	$hkTool = New-Object System.Windows.Forms.Label
	$hkTool.Location = New-Object System.Drawing.Point(4,20)
	$hkTool.Size = New-Object System.Drawing.Size(240,14)
	$hkTool.Text = "Hawt Koners Tool, by geektbee / Silver Vulpes"
	$creditsBox.Controls.Add($hkTool)

	#### Copyright label
	$scripter = New-Object System.Windows.Forms.Label
	$scripter.Location = New-Object System.Drawing.Point(4,36)
	$scripter.Size = New-Object System.Drawing.Size(200,14)
	$scripter.Text = "www.github.com/websiteCanGoHere"
	$creditsBox.Controls.Add($scripter)

	############
	# Button Actions
	############
	# Buttons will be defined afterward. I've found the actions need to be created
	#	first in order for the buttons to do anything.

	#### Cancel: Exits the configurator.
	Function cancelButton_action {

		# See if there are any identifiers still running
		$identityPids = (Import-Csv -Path "$($ENV:hktPids)" | Select-Object * | Where-Object {$_.Process -eq "Identify"}).PID

		# If there are....
		If ($identityPids) {
			# ...end them.
			ForEach ($proc in $identityPids) {
				Stop-Process -ID $proc -Force
				(Get-Content "$($ENV:hktPids)" | Where-Object {$_ -notlike "`"$proc`"*"}) | Set-Content "$($ENV:hktPids)"
			}
		}

		# We're ending the Configuraiton Form window, too. So, remove it from the process logger.
		(Get-Content "$($ENV:hktPids)" | Where-Object {$_ -notlike "*`"ConfigForm`""}) | Set-Content "$($ENV:hktPids)"

		# Close out the form right away
		$cfgForm.Close()
		$cfgForm.Dispose()
	} # End Cancel Button Action

	#### Apply: Writes data to the settings file.
	Function applyButton_action {
		# Determing if the settings files should be in a portable location or not.
		$newPortable = ($settingsBox.Controls | Where-Object {$_.Name -eq "setPortable"}).Checked
		
		# If the user wants the configuration files to be in portable....
		If ($newPortable) {
			# Set the environmental variable to the portable loction, whether it is already or not.
			Set-Item -Path ENV:hktCfgPath -Value "$($ENV:hktWrkDir)/config"
			
			# Does the location for the portable files already exist?
			If (!(Test-Path "$($ENV:hktCfgPath)")) {
				# If not, then create it.
				New-Item -ItemType Directory -Path "$($ENV:hktWrkDir)/config" -Force -Confirm:$false | Out-Null
			}
			
			# Are the configuration files in the default AppData location at all?
			"settings", "corners" | % {
				If (Test-Path "$($ENV:hktAppDataPath)/${_}.csv") {
					# If so, then move them to the new locaiton.
					Remove-Item "$($ENV:hktAppDataPath)/${_}.csv" -Force -Confirm:$false
				}
			}
		} Else {
			# The configuration files can be in the standard appdata location. Set that.
			Set-Item -Path ENV:hktCfgPath -Value "$($ENV:hktAppDataPath)"
			
			If (Test-Path "$($ENV:hktWrkDir)/config") {
				Remove-Item "$($ENV:hktWrkDir)/config/*" -Force -Recurse -Confirm:$false
				Remove-Item "$($ENV:hktWrkDir)/config" -Force -Confirm:$false
			}
		}
		
		# Creating new settings file.
		New-Item -ItemType File -Path "$($ENV:hktCfgPath)/settings.csv" -Force -Confirm:$false | Out-Null

		# Obtain the data values from the setting tab.
		$newPxBuffer = ($settingsBox.Controls | Where-Object {$_.Name -eq "setPxBuffer"}).Text
		$newRestTime = ($settingsBox.Controls | Where-Object {$_.Name -eq "setRestTime"}).Text
		$newIdTimer = ($settingsBox.Controls | Where-Object {$_.Name -eq "setIdTimer"}).Text
		$newOpenCfg = ($settingsBox.Controls | Where-Object {$_.Name -eq "setOpenCfg"}).Checked
		$newOpenCfg = If ($newOpenCfg) { 1 } Else { 0 }
		
		# Now give the settings file its headings and subsequently its data.
		Add-Content -Path "$($ENV:hktCfgPath)/settings.csv" -Force -Confirm:$false -Value "setting,value"
		Add-Content -Path "$($ENV:hktCfgPath)/settings.csv" -Force -Confirm:$false -Value "pxBuffer,$newPxBuffer"
		Add-Content -Path "$($ENV:hktCfgPath)/settings.csv" -Force -Confirm:$false -Value "restTime,$newRestTime"
		Add-Content -Path "$($ENV:hktCfgPath)/settings.csv" -Force -Confirm:$false -Value "idTimer,$newIdTimer"
		Add-Content -Path "$($ENV:hktCfgPath)/settings.csv" -Force -Confirm:$false -Value "openCfg,$newOpenCfg"

		# Now, for the Corner data.
		New-Item -ItemType File -Path "$($ENV:hktCfgPath)/corners.csv" -Force -Confirm:$false | Out-Null
		# And give it some headers.
		Add-Content -Path "$($ENV:hktCfgPath)/corners.csv" -Force -Confirm:$false -Value "monitorNam, corner, actionType, modCtrl, modAlt, modShift, modWin, modKey, cmd"

		# So! We're going to save the current settings, huh? OK! We're going to need to
		#	do that loopy thing with the displays and the four corners again.
		# $monData = [System.Windows.Forms.Screen]::AllScreens | Sort-Object Bounds
		# Call the Monitor Data function to populate an object for consumption.
		$monData = monDat
		ForEach ($screen in $monData) {
			# $monID = $screen.DeviceName -Replace "\W"
			$monID = $screen.DeviceName

			"topLeft", "topRight", "bottomLeft", "bottomRight" | % {
				$cornerLoc = $_
				# Starting the field id over again, because it was rather handy last time.
				$id = "$monID$cornerLoc"
				$fieldId = "obj$id"
				$groupId = "grp$id"

				# Get which radio button is checked.
				# Get the Radio button statuses
				$rKeyCombo = ($groupBox[$groupId].Controls | Where-Object { $_.Name -eq "rKeyCombo_$fieldId"} ).Checked
				$rCmd = ($groupBox[$groupId].Controls | Where-Object { $_.Name -eq "rCmd_$fieldId"} ).Checked
				$rDisable = ($groupBox[$groupId].Controls | Where-Object { $_.Name -eq "rDisable_$fieldId"} ).Checked

				# Get the Checkbox statuses
				$cModCtrl = ($groupBox[$groupId].Controls | Where-Object { $_.Name -eq "cModCtrl_$fieldId"} ).Checked
				$cModAlt = ($groupBox[$groupId].Controls | Where-Object { $_.Name -eq "cModAlt_$fieldId"} ).Checked
				$cModShift = ($groupBox[$groupId].Controls | Where-Object { $_.Name -eq "cModShift_$fieldId"} ).Checked
				$cModWin = ($groupBox[$groupId].Controls | Where-Object { $_.Name -eq "cModWin_$fieldId"} ).Checked

				# Get the Chosen Keyboard shortcut.
				$ddKey = ($groupBox[$groupId].Controls | Where-Object { $_.Name -eq "ddKey_$fieldId"} ).SelectedItem

				# Get any data that's in the command block.
				$tCmd = ($groupBox[$groupId].Controls | Where-Object { $_.Name -eq "tCmd_$fieldId"} ).Text

				# Determine Action type, dependent upon which radio button is checked.
				# To self: It feels like there's a better way to do this. I think in PHP, you
				#	give the field the same ID/Name, and just check out the Value. We could use
				#	a Switch case then. This language doesn't seem to be able to do it that way,
				#	that I've found, anyways.
				If ($rKeyCombo) { $actType = "KeyCombo"} ElseIf ($rCmd) { $actType = "Command" } Else { $actType = "Disabled" }

				# Now that we should now have everything, write the values to the settings file.
				Add-Content -Path "$($ENV:hktCfgPath)/corners.csv" -Force -Confirm:$false -Value "$monID,$cornerLoc,$actType,$cModCtrl,$cModAlt,$cModShift,$cModWin,$ddKey,`"$tCmd`""
			} # End adding for this corner of this screen
		} # End adding for this screen
	} # Apply action complete

	############
	# Action Buttons
	############
	# These are going at the bottom, below the tabs. I semi-modeled this after
	#	Active Directory's object's properties, because I think it helps it look
	#	organized.

	# I like consistency, so make the buttons the same size.
	$btnSizeWidth = 74
	$btnSizeHeight = 24

	#### Identify button
	$idButton = New-Object System.Windows.Forms.Button
	$idButton.Location = New-Object System.Drawing.Size(10, ($height - 72))
	$idButton.Size = New-Object System.Drawing.Size($btnSizeWidth,$btnSizeHeight)
	$idButton.Text = "Identify"
	$idButton.Add_Click({. "$($ENV:hktAssets)/identifiers.ps1"})
	$cfgForm.Controls.Add($idButton)

	#### OK button
	$okButton = New-Object System.Windows.Forms.Button
	$okButton.Location = New-Object System.Drawing.Size(($width - 260), ($height - 72))
	$okButton.Size = New-Object System.Drawing.Size($btnSizeWidth,$btnSizeHeight)
	$okButton.Text = "OK"
	$okButton.Add_Click({
		applyButton_action
		cancelButton_action
	})
	$cfgForm.Controls.Add($okButton)

	#### Cancel button
	$cancelButton = New-Object System.Windows.Forms.Button
	$cancelButton.Location = New-Object System.Drawing.Size(($width - 180), ($height - 72))
	$cancelButton.Size = New-Object System.Drawing.Size($btnSizeWidth,$btnSizeHeight)
	$cancelButton.Text = "Cancel"
	$cancelButton.Add_Click({cancelButton_action})
	$cfgForm.Controls.Add($cancelButton)

	#### Apply button
	$applyButton = New-Object System.Windows.Forms.Button
	$applyButton.Location = New-Object System.Drawing.Size(($width - 100), ($height - 72))
	$applyButton.Size = New-Object System.Drawing.Size($btnSizeWidth,$btnSizeHeight)
	$applyButton.Text = "Apply"
	$applyButton.Add_Click({applyButton_action})
	$cfgForm.Controls.Add($applyButton)

	#### The "X" Close button at the top-right.
	$cfgForm.Add_FormClosing({cancelButton_action})
	
	# I don't know or remember what this does.... but we evidently needed, and don't want to break anything by removing it.
	$cfgForm.Add_Shown({$cfgForm.Activate()})

	# Now that everything seems set all well and good, show the form.
	$cfgForm.ShowDialog()
} Else {
	(New-Object -ComObject WScript.Shell).AppActivate($ConfigFormPID)
}