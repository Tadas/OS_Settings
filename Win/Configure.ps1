Param(
	[pscredential]$CurrentUserCreds = (Get-Credential -UserName ($env:UserName) -Message "User we'll be configuring")
)
$MOF_OutputPath = "$PSScriptRoot\MOF"
try {
	$ConfigData = @{
		AllNodes = @(
			@{
				NodeName = 'localhost'
				PSDscAllowPlainTextPassword = $true
			}
		)
	}

	Configuration MyConfig {
		Import-DscResource –ModuleName 'PSDesiredStateConfiguration'

		Node "localhost" {

			# Opens the last active app instance when clicking on the taskbar (instead of opening previews)
			Registry TaskbarOpenLastActive {
				Ensure      = "Present"

				Key         = "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
				ValueName   = "LastActiveClick"
				ValueData   = "1"
				ValueType   = "Dword"
				PsDscRunAsCredential = $CurrentUserCreds
			}


			Registry TaskbarClockSeconds {
				Ensure      = "Present"

				Key         = "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
				ValueName   = "ShowSecondsInSystemClock"
				ValueData   = "1"
				ValueType   = "Dword"
				PsDscRunAsCredential = $CurrentUserCreds
			}


			# Window previews should pop up faster
			Registry TaskbarLivePreviewDelay {
				Ensure      = "Present"

				Key         = "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
				ValueName   = "ExtendedUIHoverTime"
				ValueData   = "100"
				ValueType   = "Dword"
				PsDscRunAsCredential = $CurrentUserCreds
			}


			# Disables slow fades in the taskbar
			Registry TaskbarAnimations {
				Ensure      = "Present"

				Key         = "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
				ValueName   = "TaskbarAnimations"
				ValueData   = "0"
				ValueType   = "Dword"
				PsDscRunAsCredential = $CurrentUserCreds
			}

			# Don't compress wallpapers
			Registry WallpaperCompression {
				Ensure      = "Present"

				Key         = "HKEY_CURRENT_USER\Control Panel\Desktop"
				ValueName   = "JPEGImportQuality"
				ValueData   = "100"
				ValueType   = "Dword"
				PsDscRunAsCredential = $CurrentUserCreds
			}
		}
	}
	MyConfig -OutputPath $MOF_OutputPath -ConfigurationData $ConfigData

	Start-DscConfiguration -Wait -Verbose -Path $MOF_OutputPath

} finally {
	# Clean up the MOF as it contains the credentials. Once applied it's stored encrypted (WMF 5.0)
	if (Test-Path $MOF_OutputPath -PathType Container) { Remove-Item -Recurse $MOF_OutputPath }

}