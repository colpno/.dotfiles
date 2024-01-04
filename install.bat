REM Store current directory in a variable
set "current_dir=%CD%"

REM Install Powershell
winget install --id Microsoft.Powershell --source winget

REM Install Windows Terminal
winget install --id Microsoft.WindowsTerminal -e

REM Restore Windows Terminal settings
copy /y /v "%current_dir%\powershell\settings.json" "%LocalAppData%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"

REM Install Oh My Posh
winget install JanDeDobbeleer.OhMyPosh -s winget

REM Create $PROFILE file if not exist
if not exist $PROFILE (
	New-Item -Path $PROFILE -Type File -Force
)

REM Append oh-my-posh theme init to $PROFILE
echo oh-my-posh init pwsh --config "%current_dir%\powershell\theme.omp.json" ^| Invoke-Expression >> $PROFILE

REM Install TranslucentTB
winget install TranslucentTB

REM Restore Windows Terminal settings
copy /y /v "%current_dir%\translucentTB\settings.json" "%LocalAppData%\Packages\28017CharlesMilette.TranslucentTB_v826wp6bftszj\RoamingState"