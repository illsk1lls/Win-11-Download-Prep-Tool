@ECHO OFF
SET VERSION=%~n0
SET VERSION=%VERSION:~-1%
IF NOT 1%VERSION% == 10 (
SET VERSION=1
)
SET "TitleName=Get-Win1%VERSION%"
TASKLIST /V /NH /FI "imagename eq cmd.exe"|FINDSTR /I /C:"Get-Win">nul
IF NOT %errorlevel%==1 POWERSHELL -nop -c "$^={$Notify=[PowerShell]::Create().AddScript({$Audio=New-Object System.Media.SoundPlayer;$Audio.SoundLocation=$env:WinDir + '\Media\Windows Notify System Generic.wav';$Audio.playsync()});$rs=[RunspaceFactory]::CreateRunspace();$rs.ApartmentState="^""STA"^"";$rs.ThreadOptions="^""ReuseThread"^"";$rs.Open();$Notify.Runspace=$rs;$Notify.BeginInvoke()};&$^;$PopUp=New-Object -ComObject Wscript.Shell;$PopUp.Popup("^""The script is already running!"^"",0,'ERROR:',0x10)">nul&EXIT
TITLE %TitleName%
>nul 2>&1 REG ADD HKCU\Software\Classes\.GetWin\shell\runas\command /f /ve /d "CMD /x /d /r SET \"f0=%%2\"& call \"%%2\" %%3"& SET _= %*
>nul 2>&1 FLTMC||(CD.>"%temp%\elevate.GetWin" & START "%~n0" /high "%temp%\elevate.GetWin" "%~f0" "%_:"=""%" & EXIT /b)
>nul 2>&1 REG DELETE HKCU\Software\Classes\.GetWin\ /f &>nul 2>&1 DEL %temp%\elevate.GetWin /f
ECHO Checking System...
FOR /F "usebackq skip=2 tokens=3-4" %%i IN (`REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul`) DO set "ProductName=%%i %%j"
IF "%ProductName%"=="Windows 7" ECHO/ & ECHO WINDOWS 7 DETECTED. & ECHO/ & ECHO THIS SCRIPT CANNOT RUN ON WINDOWS 7 DUE TO POWERSHELL LIMITATIONS, UPGRADE TO WIN 8/10 FIRST. & ECHO/ & PAUSE & EXIT
ECHO Started processing ISO/WIM on %date% at %time%>"%~dp0Get-Win1%VERSION%.log" & ECHO/>>"%~dp0Get-Win1%VERSION%.log"
SETLOCAL ENABLEDELAYEDEXPANSION
SET "ISO=%1"
SET /a currentindex=1
SET "rootfolder=%ProgramData%\TempSysPrep"
SET "folder=%rootfolder%\sources"
SET "TempDL=%ProgramData%\TempDL"
CALL :CENTER
ECHO/ & ECHO Getting Ready, please wait ...
IF [%1]==[] (
CALL :DOWNLOADISO
) ELSE (
CALL :DOWNLOADTOOLS
POPD & POPD
)
CALL :XBUTTON false
TITLE %TitleName% - Mounting/Extracting ISO
POWERSHELL -nop -c "Mount-DiskImage '!ISO!'">>"%~dp0Get-Win1%VERSION%.log"
FOR /f "tokens=3 delims=\:" %%d IN ('reg query hklm\system\mounteddevices ^| findstr /c:"5C003F00" ^| findstr /v "{.*}"') do (  
IF EXIST "%%d:\sources\install.wim" SET SOURCE=%%d
)
IF NOT EXIST "!SOURCE!:\sources\install.wim" ECHO/ & ECHO Incompatible ISO Detected & ECHO/ & PAUSE & EXIT /b
IF EXIST "%rootfolder%" RD "%rootfolder%" /s /q>>"%~dp0Get-Win1%VERSION%.log"
MD "%rootfolder%">>"%~dp0Get-Win1%VERSION%.log"
CLS & ECHO/ & ECHO Getting Ready, please wait...& ECHO/ & ECHO Extracting ISO...
XCOPY "!SOURCE!:\" "%rootfolder%\" /E /H /C /I /Y>>"%~dp0Get-Win1%VERSION%.log"
POWERSHELL -nop -c "Dismount-DiskImage ""!ISO!""">>"%~dp0Get-Win1%VERSION%.log"
PUSHD "%folder%"
FOR /F "usebackq tokens=3" %%i IN (`dism /get-wiminfo /wimfile:"%folder%\install.wim"`) DO (
SET index=%%i
SET index=!index:,=!
IF !index! LSS 99 SET totalindex=!index!
)
SET "REVERSEPATH=%folder:\=/%"
:APPLY
CLS
IF %currentindex% leq %totalindex% (
TITLE %TitleName% - Applying Settings to WIM ^(Index %currentindex% of %totalindex%^)
ECHO/ & ECHO Working on Index %currentindex%...
ECHO/
"%TempDL%\wimlib-imagex.exe" extract install.wim %currentindex% /Windows/System32/config/software --dest-dir="%reversepath%/%currentindex%"
ECHO/
"%TempDL%\wimlib-imagex.exe" extract install.wim %currentindex% /Windows/System32/config/system --dest-dir="%reversepath%/%currentindex%"
ECHO/
"%TempDL%\wimlib-imagex.exe" extract install.wim %currentindex% /Users/Default/ntuser.dat --dest-dir="%reversepath%/%currentindex%"
ECHO/
ECHO Updating Registry of Index %currentindex%...
REG load HKLM\tmp_software "%folder%\%currentindex%\software">>"%~dp0Get-Win1%VERSION%.log"
REG load HKLM\tmp_system "%folder%\%currentindex%\system">>"%~dp0Get-Win1%VERSION%.log"
REG load HKLM\tmp_default "%folder%\%currentindex%\ntuser.dat">>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_software\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_software\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_software\Policies\Microsoft\Edge" /v WebWidgetAllowed /t REG_DWORD /d 0 /f>nul
REG add "HKLM\tmp_software\Microsoft\Windows\CurrentVersion\RunOnce" /v EnableF8Menu /t REG_SZ /d "bcdedit /set {default} bootmenupolicy legacy" /f>>"%~dp0Get-Win1%VERSION%.log"
"%TempDL%\SetACL.exe" -on "HKLM\tmp_software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -ot reg -actn setowner -ownr "n:Administrators" -rec Yes>>"%~dp0Get-Win1%VERSION%.log"
"%TempDL%\SetACL.exe" -on "HKLM\tmp_software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec Yes>>"%~dp0Get-Win1%VERSION%.log"
REG delete "HKLM\tmp_software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_software\Policies\Microsoft\Windows\Windows Search" /v EnableDynamicContentInWSB /t REG_DWORD /d 0 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_system\ControlSet001\Control\CI\Policy" /v SkuPolicyRequired /t REG_DWORD /d 0 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_system\ControlSet001\Control\Session Manager\Configuration Manager" /v EnablePeriodicBackup /t REG_DWORD /d 1 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_system\Setup\MoSetup" /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_system\Setup\LabConfig" /v BypassTPMCheck /t REG_DWORD /d 1 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_system\Setup\LabConfig" /v BypassSecureBootCheck /t REG_DWORD /d 1 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_system\Setup\LabConfig" /v BypassRAMCheck /t REG_DWORD /d 1 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_system\Setup\LabConfig" /v BypassCPUCheck /t REG_DWORD /d 1 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_system\Setup\LabConfig" /v BypassDiskCheck /t REG_DWORD /d 1 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_system\Setup\LabConfig" /v BypassStorageCheck /t REG_DWORD /d 1 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v UseCompactMode /t REG_DWORD /d 1 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f>>"%~dp0Get-Win1%VERSION%.log"
REG add "HKLM\tmp_default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f>>"%~dp0Get-Win1%VERSION%.log"
REG unload HKLM\tmp_software>>"%~dp0Get-Win1%VERSION%.log"
REG unload HKLM\tmp_system>>"%~dp0Get-Win1%VERSION%.log"
REG unload HKLM\tmp_default>>"%~dp0Get-Win1%VERSION%.log"
ECHO/
"%TempDL%\wimlib-imagex.exe" update install.wim %currentindex% --command="add "%reversepath%/%currentindex%/SOFTWARE" Windows/System32/config/SOFTWARE"
ECHO/
"%TempDL%\wimlib-imagex.exe" update install.wim %currentindex% --command="add "%reversepath%/%currentindex%/SYSTEM" Windows/System32/config/SYSTEM"
ECHO/
"%TempDL%\wimlib-imagex.exe" update install.wim %currentindex% --command="add "%reversepath%/%currentindex%/ntuser.dat" Users/Default/ntuser.dat"
ECHO/
RD "%folder%\%currentindex%" /s /q>>"%~dp0Get-Win1%VERSION%.log"
) ELSE (
GOTO FINALIZE
)
SET /a currentindex+=1
GOTO APPLY
:FINALIZE
TITLE %TitleName% - Please Wait...
POPD
ECHO/ & ECHO Adding TPM skip and Update refresh...
CALL :ADDUNSUPPORTEDCMD
ECHO/ & ECHO Re-Building ISO, please wait...
CALL :MAKEISO
DEL "%ProgramData%\MakeIso.ps1" /f /q>nul
ECHO/>>"%~dp0Get-Win1%VERSION%.log"
RD "%rootfolder%" /s /q>>"%~dp0Get-Win1%VERSION%.log"
IF EXIST "%TempDL%\download.1%VERSION%.link" (
MOVE /Y "%TempDL%\download.1%VERSION%.link" "%ProgramData%">nul && (ECHO download.1%VERSION%.link moved out of %TempDL%>>"%~dp0Get-Win1%VERSION%.log") || (ECHO Error moving download.1%VERSION%.link out of %TempDL%>>"%~dp0Get-Win1%VERSION%.log")
RD "%TempDL%" /S /Q>>"%~dp0Get-Win1%VERSION%.log"
MD "%TempDL%">>"%~dp0Get-Win1%VERSION%.log"
MOVE /Y "%ProgramData%\download.1%VERSION%.link" "%TempDL%">nul && (ECHO download.1%VERSION%.link moved to %TempDL%>>"%~dp0Get-Win1%VERSION%.log") || (ECHO Error moving download.1%VERSION%.link to %TempDL%>>"%~dp0Get-Win1%VERSION%.log")
) ELSE (
RD "%TempDL%" /S /Q>>"%~dp0Get-Win1%VERSION%.log"
)
ECHO/>>"%~dp0Get-Win1%VERSION%.log" & ECHO Completed processing ISO/WIM on %date% at %time%>>"%~dp0Get-Win1%VERSION%.log"
TITLE %TitleName% - Process Complete.
ECHO/ & ECHO Process Complete.. & ECHO/ & ECHO ISO Updated & ECHO/ & ECHO "Win1!VERSION!_Eng_x64.iso" is located in the same folder as this script. ;^) & ECHO/
CALL :XBUTTON true
PAUSE
ENDLOCAL
EXIT /b
:XBUTTON
>nul 2>&1 POWERSHELL -nop -c "(Add-Type -PassThru 'using System; using System.Runtime.InteropServices; namespace CloseButtonToggle { internal static class WinAPI { [DllImport(\"kernel32.dll\")] internal static extern IntPtr GetConsoleWindow(); [DllImport(\"user32.dll\")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool DeleteMenu(IntPtr hMenu, uint uPosition, uint uFlags); [DllImport(\"user32.dll\")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool DrawMenuBar(IntPtr hWnd); [DllImport(\"user32.dll\")] internal static extern IntPtr GetSystemMenu(IntPtr hWnd, [MarshalAs(UnmanagedType.Bool)]bool bRevert); const uint SC_CLOSE = 0xf060; const uint MF_BYCOMMAND = 0; internal static void ChangeCurrentState(bool state) { IntPtr hMenu = GetSystemMenu(GetConsoleWindow(), state); DeleteMenu(hMenu, SC_CLOSE, MF_BYCOMMAND); DrawMenuBar(GetConsoleWindow()); } } public static class Status { public static void Disable() { WinAPI.ChangeCurrentState(%1); } } }')[-1]::Disable()"
EXIT /b
:CENTER
>nul 2>&1 POWERSHELL -nop -c "$w=Add-Type -Name WAPI -PassThru -MemberDefinition '[DllImport(\"user32.dll\")]public static extern void SetProcessDPIAware();[DllImport(\"shcore.dll\")]public static extern void SetProcessDpiAwareness(int value);[DllImport(\"kernel32.dll\")]public static extern IntPtr GetConsoleWindow();[DllImport(\"user32.dll\")]public static extern void GetWindowRect(IntPtr hwnd, int[] rect);[DllImport(\"user32.dll\")]public static extern void GetClientRect(IntPtr hwnd, int[] rect);[DllImport(\"user32.dll\")]public static extern void GetMonitorInfoW(IntPtr hMonitor, int[] lpmi);[DllImport(\"user32.dll\")]public static extern IntPtr MonitorFromWindow(IntPtr hwnd, int dwFlags);[DllImport(\"user32.dll\")]public static extern int SetWindowPos(IntPtr hwnd, IntPtr hwndAfterZ, int x, int y, int w, int h, int flags);';$PROCESS_PER_MONITOR_DPI_AWARE=2;try {$w::SetProcessDpiAwareness($PROCESS_PER_MONITOR_DPI_AWARE)} catch {$w::SetProcessDPIAware()}$hwnd=$w::GetConsoleWindow();$moninf=[int[]]::new(10);$moninf[0]=40;$MONITOR_DEFAULTTONEAREST=2;$w::GetMonitorInfoW($w::MonitorFromWindow($hwnd, $MONITOR_DEFAULTTONEAREST), $moninf);$monwidth=$moninf[7] - $moninf[5];$monheight=$moninf[8] - $moninf[6];$wrect=[int[]]::new(4);$w::GetWindowRect($hwnd, $wrect);$winwidth=$wrect[2] - $wrect[0];$winheight=$wrect[3] - $wrect[1];$x=[int][math]::Round($moninf[5] + $monwidth / 2 - $winwidth / 2);$y=[int][math]::Round($moninf[6] + $monheight / 2 - $winheight / 2);$SWP_NOSIZE=0x0001;$SWP_NOZORDER=0x0004;exit [int]($w::SetWindowPos($hwnd, [IntPtr]::Zero, $x, $y, 0, 0, $SWP_NOSIZE -bOr $SWP_NOZORDER) -eq 0)"
EXIT /b
:MAKEISO
TITLE %TitleName% - Rebuilding ISO
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://raw.githubusercontent.com/wikijm/PowerShell-AdminScripts/master/Miscellaneous/New-IsoFile.ps1 -o '%ProgramData%\MakeIso.ps1'"
ECHO $source_dir = "%rootfolder%">>"%ProgramData%\MakeIso.ps1"
ECHO get-childitem "$source_dir" ^| New-ISOFile -force -path "%~dp0Win1%VERSION%_Eng_x64.iso" -BootFile %rootfolder%\efi\microsoft\boot\efisys.bin -Title "Win1%VERSION%-ReadyToInstall">>"%ProgramData%\MakeIso.ps1"
POWERSHELL -nop -c "Dismount-DiskImage ""%~dp0Win1%VERSION%_Eng_x64.iso""">nul
POWERSHELL -nop -ep bypass -f "%ProgramData%\MakeIso.ps1">nul
EXIT /b
:DOWNLOADTOOLS
TITLE %TitleName% - Downloading Tools
CLS
PING -n 1 "google.com" | findstr /r /c:"[0-9] *ms">nul
IF NOT %errorlevel% == 0 ECHO/ & ECHO Internet connection not detected! & ECHO/ & RD "%rootfolder%" /S /Q>nul & PAUSE & EXIT
IF NOT EXIST "%TempDL%" MD "%TempDL%">nul
IF EXIST "%TempDL%\Junkbin" RD "%TempDL%\Junkbin" /S /Q>nul
MD "%TempDL%\Junkbin">nul
ECHO/ & ECHO Getting Tools...
PUSHD "%TempDL%" & PUSHD "%TempDL%\Junkbin"
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://www.7-zip.org/a/7zr.exe -o '7zr.exe'"; "Invoke-WebRequest -Uri https://www.7-zip.org/a/7z2300-extra.7z -o '7zExtra.7z'"; "Invoke-WebRequest -Uri https://wimlib.net/downloads/wimlib-1.14.1-windows-x86_64-bin.zip -o 'wimlib.zip'"; "Invoke-WebRequest -Uri https://helgeklein.com/downloads/SetACL/current/SetACL%%203.1.2%%20`(executable%%20version`).zip -o 'SetACL.zip'"
7zr.exe e -y 7zExtra.7z>nul & 7za.exe e -y wimlib.zip libwim-15.dll -r -o..>nul & 7za.exe e -y wimlib.zip wimlib-imagex.exe -r -o..>nul & 7za.exe e -y SetACL.zip "SetACL (executable version)\64 bit\SetACL.exe" -r -o..>nul
EXIT /b
:DOWNLOADISO
CALL :DOWNLOADTOOLS
TITLE %TitleName% - Downloading ISO
CLS
ECHO/ & ECHO Preparing for ISO Download...
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0-win-64bit-build1.zip -o 'Aria2c.zip'"; "Invoke-WebRequest -Uri https://raw.githubusercontent.com/pbatard/Fido/master/Fido.ps1 -o 'Fido.ps1'"
7za.exe e -y Aria2c.zip Aria2c.exe -r -o..>nul & MOVE /Y Fido.ps1 ..>nul && (ECHO Fido.ps1 moved to %TempDL%>>"%~dp0Get-Win1%VERSION%.log") || (ECHO Error moving Fido.ps1 to %TempDL%>>"%~dp0Get-Win1%VERSION%.log") & POPD
IF EXIST download.1%VERSION%.link (
FORFILES /d -1 /m "download.1%VERSION%.link" >NUL 2>NUL && (
DEL "%TempDL%\download.1%VERSION%.link" /F /Q>nul
CALL :GETLINK
) || (
ECHO/ & ECHO Re-Using Existing Download Link...
SET /p link=<download.1%VERSION%.link
)
) ELSE (
CALL :GETLINK
)
IF EXIST Win1%VERSION%_Eng_x64.iso (
FORFILES /d -3 /m "Win1%VERSION%_Eng_x64.iso" >NUL 2>NUL && (
DEL "%TempDL%\Win1%VERSION%_Eng_x64.iso" /F /Q>nul
ECHO/ & ECHO Starting ISO Download...
) || (
ECHO/ & ECHO Resuming ISO Download...
)
) ELSE (
ECHO/ & ECHO Starting ISO Download...
)
"%TempDL%\aria2c.exe" --continue=true --summary-interval=0 --file-allocation=none --auto-file-renaming=false --max-connection-per-server=5 "!link!" -o Win1%VERSION%_Eng_x64.iso
POWERSHELL -nop -c "Dismount-DiskImage '%~dp0Win1%VERSION%_Eng_x64.iso'">nul
MOVE /Y "Win1%VERSION%_Eng_x64.iso" "%~dp0">nul && (ECHO Download completed and Win1%VERSION%_Eng_x64.iso moved to %~dp0>>"%~dp0Get-Win1%VERSION%.log") || (ECHO Error moving Win1%VERSION%_Eng_x64.iso to %~dp0>>"%~dp0Get-Win1%VERSION%.log")
SET ISO="%~dp0Win1%VERSION%_Eng_x64.iso"
POPD
EXIT /b
:GETLINK
ECHO/ & ECHO Requesting Download from Microsoft...
FOR /f "delims=" %%A in ('powershell -nop -ep bypass -c ".\fido.ps1 -Win 1%VERSION% -Lang Eng -Arch x64 -GetUrl"') DO SET "link=%%A"
ECHO !link!>download.1%VERSION%.link
EXIT /b
:ADDUNSUPPORTEDCMD
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://raw.githubusercontent.com/AveYo/MediaCreationTool.bat/main/bypass11/Skip_TPM_Check_on_Dynamic_Update.cmd -o '%rootfolder%\Skip_TPM_Check_on_Dynamic_Update.cmd'"; "Invoke-WebRequest -Uri https://raw.githubusercontent.com/AveYo/MediaCreationTool.bat/main/bypass11/windows_update_refresh.bat -o '%rootfolder%\windows_update_refresh.bat'"
EXIT /b