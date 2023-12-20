
# Is the identifier already running?
$idPids = (Import-Csv -Path "$($ENV:hktPids)" | Select-Object * | Where-Object {$_.Process -eq "Identify"}).PID

If ($idPids) {
	# The Identifiers are are already running; stop them.
	ForEach ($proc in $idPids) {
		# Stopping this one.
		Stop-Process -ID $proc -Force

		# Remove that PID from the file.
		(Get-Content "$($ENV:hktPids)" | Where-Object {$_ -notlike "`"$proc`"*"}) | Set-Content "$($ENV:hktPids)"
	}
} Else {
	# Get the Working Area of the screens now.
	# $monData = ([System.Windows.Forms.Screen]::AllScreens | Sort-Object Bounds).WorkingArea
	# Call the Monitor Data function to populate an object for consumption.
	# Bring in the Functions for imaging.
	. "$($ENV:hktAssets)/functions.ps1"
	$monData = monDat
	$i = 0

	ForEach ($screen in $monData) {
		# So we know which display we're workin' on.
		$monNum = $i + 1

		# Starting a new job. I've found the form loads much, much, much faster this
		#	way. It makes it a bit more tricky though, and is the reason we use the
		#	process.pid file now. And, instead of re-calculating all the things, we can
		#	just pass them in. That saves on some calculation time, too.
		Start-Job -ArgumentList $screen,$monNum -ScriptBlock {
			param($screen,$monNum)

			# We've got a new process id to log. Log it.
			Add-Content -Path "$($ENV:hktPids)" -Force -Confirm:$false -Value "`"$PID`",`"Identify`""

			# Load up the needed Forms feature.
			[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
			[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

			# Where do we want the form to show up at on each screen?
			# Bottom-Left
			# $posX = [Math]::Ceiling($screen.Left + ($screen.Width * .05))
			# $posY = [Math]::Ceiling($screen.Bottom - ($screen.Height * .25))
			#### Top-Left
			$posX = $screen.Bounds.X + 25
			$posY = $screen.Bounds.Y + 25

			# New Form for a new screen
			$scrMarker = New-Object System.Windows.Forms.Form -Property @{TopMost=$true}
			$scrMarker.Location = New-Object System.Drawing.Point($posX,$posY)
			$scrMarker.Name = "form$monNum"
			$scrMarker.FormBorderStyle = "None"
			$scrMarker.StartPosition = "Manual"
			$scrMarker.BackColor = "#B68F52"		# Honey Mustard
			$scrMarker.Width = 200
			$scrMarker.Height = 200
			$scrMarker.Location.X = $posX
			$scrMarker.Location.Y = $posY
			$scrMarker.ShowInTaskbar = $false

			# Background. I couldn't find a better way to do this than with a label. The Shape feature wouldn't play well.
			$bgLabel = New-Object System.Windows.Forms.Label
			$bgLabel.Location = New-Object System.Drawing.Point(15,15)
			$bgLabel.Size = New-Object System.Drawing.Size(170,170)
			$bgLabel.Text = ""
			$bgLabel.BackColor = "#003314"	# Deep Forest
			$bgLabel.Font = [System.Drawing.Font]::new("Times New Roman", 110, [System.Drawing.FontStyle]::Bold)
			$scrMarker.Controls.Add($bgLabel)

			# The number. For the screen. Of life.
			$label = New-Object System.Windows.Forms.Label
			$label.Location = New-Object System.Drawing.Point(24,2)
			$label.Size = New-Object System.Drawing.Size(160,160)
			$label.Text = "$monNum"
			$label.ForeColor = "#CF210A"	# Fresh Blood
			$label.Font = [System.Drawing.Font]::new("Times New Roman", 110, [System.Drawing.FontStyle]::Bold)
			$bgLabel.Controls.Add($label)

			# Attempt to bring the label to the front, because, ya'know, we want to see it.
			$scrMarker.$label.BringToFront()

			# Get the configuration settings from the settings file.
			If (Test-Path "$($ENV:hktCfgPath)/settings.csv") {
				$cfgData = Import-Csv -Path "$($ENV:hktCfgPath)/settings.csv"
				$cfg = $cfgData | Group-Object -AsHashTable -Property "setting"
				$idTimer = [int]$cfg['idTimer'].Value
			} Else {
				$idTimer = 7
			}

			$keepOpen = If ($idTimer -eq 0) { $true } Else { $false }
			
			# Should the Numbers go way soon?
			If (!$keepOpen) {
				# Yes? Okay. Build a timer.
				$timer = New-Object System.Windows.Forms.Timer
				$timer.Interval = $idTimer * 1000
				# What are we going to do when the timer is up? We'll close the form.
				$timer.Add_Tick({ $scrMarker.Close() })
				# Start the timer.
				$timer.Start()
			}

			# Show the form on this screen. Now, if the timer wasn't set because we're
			#	supposed to keep the form open forever, this command hangs. That's a good
			#	thing, though. We get to end it via the Process ID we got earlier when the
			#	user clicks the Identify button again.
			$formResult = $scrMarker.ShowDialog()

			If (!$keepOpen) {
				# We don't need the timer anymore, if we used it.
				$timer.Dispose()
			}

			# And we don't need the form anymore, either.
			$scrMarker.Dispose()

			# We can remove the Process from the pid tracker now; it's about to close itself.
			(Get-Content "$($ENV:hktPids)" | Where-Object {$_ -notlike "`"$PID`"*"}) | Set-Content "$($ENV:hktPids)"
		} | Out-Null
		$i++
	}	# End ForEach Screen
} # End Running PID Check
