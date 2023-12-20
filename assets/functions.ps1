Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms,PresentationFramework

Function b64toImg($base64) {
	# Converts base64 jargon to an image.
	# Originally used for the donate images; but can be used for other stuff now,
	#	too.
	$thaBytes = [Convert]::FromBase64String($base64)
	$memStream = New-Object IO.MemoryStream($thaBytes, 0, $thaBytes.Length)
	$memStream.Write($thaBytes, 0, $thaBytes.Length);
	$finalImg = [System.Drawing.Image]::FromStream($memStream, $true)

	Return $finalImg
}

Function b64toIco($base64) {
	# Converts base64 jargon to an icon picture.
	$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
	$bitmap.BeginInit()
	$bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($Base64)
	$bitmap.EndInit()
	$bitmap.Freeze()
	$image = [System.Drawing.Bitmap][System.Drawing.Image]::FromStream($bitmap.StreamSource)
	$icon = [System.Drawing.Icon]::FromHandle($image.GetHicon())
	
	Return $icon
}

Function findSettings {
	# Finds where the configuration settings files are at.
	# Help to determine Portable Vs. AppData save location.
	If (Test-Path "$($ENV:hktWrkDir)/config/settings.csv") {
		Return "$($ENV:hktWrkDir)/config"
	} ElseIf (Test-Path "$($ENV:hktAppDataPath)/settings.csv") {
		Return "$($ENV:hktAppDataPath)"
	} Else {
		Return $false
	}
}

Function monDat {
	# Get only the monitor data needed, sorts it well, and names it something more
	# reasonable than \\.\DISPLAY5 when there's one 2 screens (from experience)
	$loopCnt = 0
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	[System.Windows.Forms.Screen]::AllScreens | Sort-Object -Property @{E={$_.Bounds.X}},@{E={$_.Bounds.Y}} | ForEach {
		$loopCnt++
		[PSCustomObject]@{
			DeviceName = "Display_$loopCnt"
			Bounds = $_.Bounds
		}
	}
}