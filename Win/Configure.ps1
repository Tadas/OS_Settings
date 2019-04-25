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

			# File Explorer - hide various locations from 'This PC'
			@(
				'Hide_3D_Objects | {31C0DD25-9439-4F12-BF41-7FF4EDA38722}',
				'Hide_Music      | {A0C69A99-21C8-4671-8703-7934162FCF1D}',
				'Hide_Videos     | {35286A68-3C57-41A1-BBB1-0EAE73D76C95}',
				'Hide_Desktop    | {B4BFCC3A-DB2C-424C-B029-7FE99A87C641}'
			) | ForEach-Object {
				$Name, $Guid = $_.Split('|').Trim()
				Registry $Name {
					Ensure      = 'Present'
	
					Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\$Guid\PropertyBag"
					ValueName   = 'ThisPCPolicy'
					ValueData   = 'Hide'
					ValueType   = 'String'
				}
			}

			# File Explorer - hide OneDrive location
			Registry Hide_OneDrive_Location {
				Ensure      = 'Present'

				Key         = 'HKEY_LOCAL_MACHINE\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
				ValueName   = 'System.IsPinnedToNameSpaceTree'
				ValueData   = '0'
				ValueType   = 'Dword'
			}
		}
	}
	MyConfig -OutputPath $MOF_OutputPath -ConfigurationData $ConfigData

	Start-DscConfiguration -Wait -Verbose -Path $MOF_OutputPath -Force

} finally {
	# Clean up the MOF as it contains the credentials. Once applied it's stored encrypted (WMF 5.0)
	if (Test-Path $MOF_OutputPath -PathType Container) { Remove-Item -Recurse $MOF_OutputPath }

}