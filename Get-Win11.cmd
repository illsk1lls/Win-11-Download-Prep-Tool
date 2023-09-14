@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
SET VERSION=%~n0
SET VERSION=%VERSION:~-1%
IF NOT 1%VERSION% == 10 (
SET VERSION=1
)
TITLE Windows 1%VERSION% - Download and System Prep Tool
>nul 2>&1 REG ADD HKCU\Software\Classes\.GetWin\shell\runas\command /f /ve /d "CMD /x /d /r SET \"f0=%%2\"& call \"%%2\" %%3"& SET _= %*
>nul 2>&1 FLTMC||(CD.>"%temp%\elevate.GetWin" & START "%~n0" /high "%temp%\elevate.GetWin" "%~f0" "%_:"=""%" & EXIT /b)
>nul 2>&1 REG DELETE HKCU\Software\Classes\.GetWin\ /f &>nul 2>&1 DEL %temp%\elevate.GetWin /f
ECHO Checking System...
FOR /F "usebackq skip=2 tokens=3-4" %%i IN (`REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul`) DO set "ProductName=%%i %%j"
IF "%ProductName%"=="Windows 7" ECHO. & ECHO WINDOWS 7 DETECTED. & ECHO. & ECHO THIS SCRIPT CANNOT RUN ON WINDOWS 7 DUE TO POWERSHELL LIMITATIONS, UPGRADE TO WIN 8/10 FIRST. & ECHO. & PAUSE & EXIT
ECHO Started processing ISO/WIM on %date% at %time%>"%~dp0WimFix.log" & ECHO.>>"%~dp0WimFix.log"
SET ISO=%1
SET currentindex=1
SET "rootfolder=%ProgramData%\TempSysPrep"
SET "folder=%rootfolder%\sources"
SET "TempDL=%ProgramData%\TempDL"
CALL :CENTER
ECHO. & ECHO Getting Ready, please wait ...
IF [%1]==[] (
CALL :DOWNLOADISO
) ELSE (
CALL :DOWNLOADTOOLS
POPD & POPD
)
CALL :XBUTTON false
TITLE Mounting/Extracting ISO
POWERSHELL -nop -c "Mount-DiskImage ""!ISO!""">>"%~dp0WimFix.log"
FOR /f "tokens=3 delims=\:" %%d IN ('reg query hklm\system\mounteddevices ^| findstr /c:"5C003F00" ^| findstr /v "{.*}"') do (  
IF EXIST "%%d:\sources\install.wim" SET SOURCE=%%d
)
IF NOT EXIST "%SOURCE%:\sources\install.wim" ECHO. & ECHO Incompatible ISO Detected!! & ECHO. & PAUSE & EXIT /b
IF EXIST "%rootfolder%" RD "%rootfolder%" /s /q>>"%~dp0WimFix.log"
MD "%rootfolder%">>"%~dp0WimFix.log"
CLS & ECHO. & ECHO Getting Ready, please wait...& ECHO. & ECHO Extracting ISO...
XCOPY "%SOURCE%:\" "%rootfolder%\" /E /H /C /I /Y>>"%~dp0WimFix.log"
POWERSHELL -nop -c "Dismount-DiskImage ""!ISO!""">>"%~dp0WimFix.log"
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
TITLE Applying Settings to WIM ^(Index %currentindex% of %totalindex%^)
ECHO. & ECHO Working on Index %currentindex%...
ECHO.
"%TempDL%\wimlib-imagex.exe" extract install.wim %currentindex% /Windows/System32/config/software --dest-dir="%reversepath%/%currentindex%"
ECHO.
"%TempDL%\wimlib-imagex.exe" extract install.wim %currentindex% /Windows/System32/config/system --dest-dir="%reversepath%/%currentindex%"
ECHO.
"%TempDL%\wimlib-imagex.exe" extract install.wim %currentindex% /Users/Default/ntuser.dat --dest-dir="%reversepath%/%currentindex%"
ECHO.
ECHO Updating Registry of Index %currentindex%...
REG load HKLM\tmp_software "%folder%\%currentindex%\software">>"%~dp0WimFix.log"
REG load HKLM\tmp_system "%folder%\%currentindex%\system">>"%~dp0WimFix.log"
REG load HKLM\tmp_default "%folder%\%currentindex%\ntuser.dat">>"%~dp0WimFix.log"
REG add "HKLM\tmp_software\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_software\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_software\Policies\Microsoft\Edge" /v WebWidgetAllowed /t REG_DWORD /d 0 /f>nul
REG add "HKLM\tmp_software\Microsoft\Windows\CurrentVersion\RunOnce" /v EnableF8Menu /t REG_SZ /d "bcdedit /set {default} bootmenupolicy legacy" /f>>"%~dp0WimFix.log"
"%TempDL%\SetACL.exe" -on "HKLM\tmp_software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -ot reg -actn setowner -ownr "n:Administrators" -rec Yes>>"%~dp0WimFix.log"
"%TempDL%\SetACL.exe" -on "HKLM\tmp_software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec Yes>>"%~dp0WimFix.log"
REG delete "HKLM\tmp_software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_software\Policies\Microsoft\Windows\Windows Search" /v EnableDynamicContentInWSB /t REG_DWORD /d 0 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_system\ControlSet001\Control\CI\Policy" /v SkuPolicyRequired /t REG_DWORD /d 0 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_system\ControlSet001\Control\Session Manager\Configuration Manager" /v EnablePeriodicBackup /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_system\Setup\MoSetup" /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_system\Setup\LabConfig" /v BypassTPMCheck /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_system\Setup\LabConfig" /v BypassSecureBootCheck /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_system\Setup\LabConfig" /v BypassRAMCheck /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_system\Setup\LabConfig" /v BypassCPUCheck /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_system\Setup\LabConfig" /v BypassDiskCheck /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_system\Setup\LabConfig" /v BypassStorageCheck /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v UseCompactMode /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add "HKLM\tmp_default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f>>"%~dp0WimFix.log"
REG unload HKLM\tmp_software>>"%~dp0WimFix.log"
REG unload HKLM\tmp_system>>"%~dp0WimFix.log"
REG unload HKLM\tmp_default>>"%~dp0WimFix.log"
ECHO.
"%TempDL%\wimlib-imagex.exe" update install.wim %currentindex% --command="add "%reversepath%/%currentindex%/SOFTWARE" Windows/System32/config/SOFTWARE"
ECHO.
"%TempDL%\wimlib-imagex.exe" update install.wim %currentindex% --command="add "%reversepath%/%currentindex%/SYSTEM" Windows/System32/config/SYSTEM"
ECHO.
"%TempDL%\wimlib-imagex.exe" update install.wim %currentindex% --command="add "%reversepath%/%currentindex%/ntuser.dat" Users/Default/ntuser.dat"
ECHO.
RD "%folder%\%currentindex%" /s /q>>"%~dp0WimFix.log"
) ELSE (
GOTO FINALIZE
)
SET /a currentindex+=1
GOTO APPLY
:FINALIZE
TITLE Please Wait...
POPD
CALL :ADDUNSUPPORTEDCMD
ECHO. & ECHO Updating ISO, please wait...
CALL :MAKEISO
DEL "%ProgramData%\MakeIso.ps1" /f /q>nul
ECHO.>>"%~dp0WimFix.log"
RD "%rootfolder%" /s /q>>"%~dp0WimFix.log"
IF EXIST "%TempDL%\download.1%VERSION%.link" (
MOVE /Y "%TempDL%\download.1%VERSION%.link" "%ProgramData%">nul && (ECHO download.1%VERSION%.link moved out of %TempDL%>>"%~dp0WimFix.log") || (ECHO Error moving download.1%VERSION%.link out of %TempDL%>>"%~dp0WimFix.log")
RD "%TempDL%" /S /Q>>"%~dp0WimFix.log"
MD "%TempDL%">>"%~dp0WimFix.log"
MOVE /Y "%ProgramData%\download.1%VERSION%.link" "%TempDL%">nul && (ECHO download.1%VERSION%.link moved to %TempDL%>>"%~dp0WimFix.log") || (ECHO Error moving download.1%VERSION%.link to %TempDL%>>"%~dp0WimFix.log")
) ELSE (
RD "%TempDL%" /S /Q>>"%~dp0WimFix.log"
)
ECHO.>>"%~dp0WimFix.log" & ECHO Completed processing ISO/WIM on %date% at %time%>>"%~dp0WimFix.log"
TITLE Process Complete.
ECHO. & ECHO Process Complete.. & ECHO. & ECHO ISO Updated & ECHO. & ECHO "Win1!VERSION!_Eng_x64.iso" is located in the same folder as this script. ;^) & ECHO.
CALL :XBUTTON true
PAUSE
ENDLOCAL
EXIT /b
:XBUTTON
>nul 2>&1 POWERSHELL -nop -ep bypass -c "(Add-Type -PassThru 'using System; using System.Runtime.InteropServices; namespace CloseButtonToggle { internal static class WinAPI { [DllImport(\"kernel32.dll\")] internal static extern IntPtr GetConsoleWindow(); [DllImport(\"user32.dll\")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool DeleteMenu(IntPtr hMenu, uint uPosition, uint uFlags); [DllImport(\"user32.dll\")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool DrawMenuBar(IntPtr hWnd); [DllImport(\"user32.dll\")] internal static extern IntPtr GetSystemMenu(IntPtr hWnd, [MarshalAs(UnmanagedType.Bool)]bool bRevert); const uint SC_CLOSE = 0xf060; const uint MF_BYCOMMAND = 0; internal static void ChangeCurrentState(bool state) { IntPtr hMenu = GetSystemMenu(GetConsoleWindow(), state); DeleteMenu(hMenu, SC_CLOSE, MF_BYCOMMAND); DrawMenuBar(GetConsoleWindow()); } } public static class Status { public static void Disable() { WinAPI.ChangeCurrentState(%1); } } }')[-1]::Disable()"
EXIT /b
:CENTER
>nul 2>&1 POWERSHELL -nop -ep Bypass -c "$w=Add-Type -Name WAPI -PassThru -MemberDefinition '[DllImport(\"user32.dll\")]public static extern void SetProcessDPIAware();[DllImport(\"shcore.dll\")]public static extern void SetProcessDpiAwareness(int value);[DllImport(\"kernel32.dll\")]public static extern IntPtr GetConsoleWindow();[DllImport(\"user32.dll\")]public static extern void GetWindowRect(IntPtr hwnd, int[] rect);[DllImport(\"user32.dll\")]public static extern void GetClientRect(IntPtr hwnd, int[] rect);[DllImport(\"user32.dll\")]public static extern void GetMonitorInfoW(IntPtr hMonitor, int[] lpmi);[DllImport(\"user32.dll\")]public static extern IntPtr MonitorFromWindow(IntPtr hwnd, int dwFlags);[DllImport(\"user32.dll\")]public static extern int SetWindowPos(IntPtr hwnd, IntPtr hwndAfterZ, int x, int y, int w, int h, int flags);';$PROCESS_PER_MONITOR_DPI_AWARE=2;try {$w::SetProcessDpiAwareness($PROCESS_PER_MONITOR_DPI_AWARE)} catch {$w::SetProcessDPIAware()}$hwnd=$w::GetConsoleWindow();$moninf=[int[]]::new(10);$moninf[0]=40;$MONITOR_DEFAULTTONEAREST=2;$w::GetMonitorInfoW($w::MonitorFromWindow($hwnd, $MONITOR_DEFAULTTONEAREST), $moninf);$monwidth=$moninf[7] - $moninf[5];$monheight=$moninf[8] - $moninf[6];$wrect=[int[]]::new(4);$w::GetWindowRect($hwnd, $wrect);$winwidth=$wrect[2] - $wrect[0];$winheight=$wrect[3] - $wrect[1];$x=[int][math]::Round($moninf[5] + $monwidth / 2 - $winwidth / 2);$y=[int][math]::Round($moninf[6] + $monheight / 2 - $winheight / 2);$SWP_NOSIZE=0x0001;$SWP_NOZORDER=0x0004;exit [int]($w::SetWindowPos($hwnd, [IntPtr]::Zero, $x, $y, 0, 0, $SWP_NOSIZE -bOr $SWP_NOZORDER) -eq 0)"
EXIT /b
:MAKEISO
TITLE Rebuilding ISO
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://raw.githubusercontent.com/wikijm/PowerShell-AdminScripts/master/Miscellaneous/New-IsoFile.ps1 -o '%ProgramData%\MakeIso.ps1'"
ECHO $source_dir = "%rootfolder%">>"%ProgramData%\MakeIso.ps1"
ECHO get-childitem "$source_dir" ^| New-ISOFile -force -path "%~dp0Win1%VERSION%_Eng_x64.iso" -BootFile %rootfolder%\efi\microsoft\boot\efisys.bin -Title "Win1%VERSION%-ReadyToInstall">>"%ProgramData%\MakeIso.ps1"
POWERSHELL -nop -c "Dismount-DiskImage ""%~dp0Win1%VERSION%_Eng_x64.iso""">nul
POWERSHELL -nop -ep bypass -f "%ProgramData%\MakeIso.ps1">nul
EXIT /b
:DOWNLOADTOOLS
TITLE Downloading Tools
CLS
PING -n 1 "google.com" | findstr /r /c:"[0-9] *ms">nul
IF NOT %errorlevel% == 0 ECHO. & ECHO Internet connection not detected! & ECHO. & RD "%rootfolder%" /S /Q>nul & PAUSE & EXIT
IF NOT EXIST "%TempDL%" MD "%TempDL%">nul
IF EXIST "%TempDL%\Junkbin" RD "%TempDL%\Junkbin" /S /Q>nul
MD "%TempDL%\Junkbin">nul
ECHO. & ECHO Getting Tools...
PUSHD "%TempDL%" & PUSHD "%TempDL%\Junkbin"
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://www.7-zip.org/a/7zr.exe -o '7zr.exe'"; "Invoke-WebRequest -Uri https://www.7-zip.org/a/7z2300-extra.7z -o '7zExtra.7z'"; "Invoke-WebRequest -Uri https://wimlib.net/downloads/wimlib-1.14.1-windows-x86_64-bin.zip -o 'wimlib.zip'"; "Invoke-WebRequest -Uri https://helgeklein.com/downloads/SetACL/current/SetACL%%203.1.2%%20`(executable%%20version`).zip -o 'SetACL.zip'"
7zr.exe e -y 7zExtra.7z>nul & 7za.exe e -y wimlib.zip libwim-15.dll -r -o..>nul & 7za.exe e -y wimlib.zip wimlib-imagex.exe -r -o..>nul & 7za.exe e -y SetACL.zip "SetACL (executable version)\64 bit\SetACL.exe" -r -o..>nul
EXIT /b
:DOWNLOADISO
CALL :DOWNLOADTOOLS
TITLE Getting Windows 1%VERSION%
CLS
ECHO. & ECHO Preparing for ISO Download...
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0-win-64bit-build1.zip -o 'Aria2c.zip'"; "Invoke-WebRequest -Uri https://raw.githubusercontent.com/pbatard/Fido/master/Fido.ps1 -o 'Fido.ps1'"
7za.exe e -y Aria2c.zip Aria2c.exe -r -o..>nul & MOVE /Y Fido.ps1 ..>nul && (ECHO Fido.ps1 moved to %TempDL%>>"%~dp0WimFix.log") || (ECHO Error moving Fido.ps1 to %TempDL%>>"%~dp0WimFix.log") & POPD
IF EXIST download.1%VERSION%.link (
FORFILES /d -1 /m "download.1%VERSION%.link" >NUL 2>NUL && (
DEL "%TempDL%\download.1%VERSION%.link" /F /Q>nul
CALL :GETLINK
) || (
ECHO. & ECHO Re-Using Existing Download Link...
SET /p link=<download.1%VERSION%.link
)
) ELSE (
CALL :GETLINK
)
IF EXIST Win1%VERSION%_Eng_x64.iso (
FORFILES /d -3 /m "Win1%VERSION%_Eng_x64.iso" >NUL 2>NUL && (
DEL "%TempDL%\Win1%VERSION%_Eng_x64.iso" /F /Q>nul
ECHO. & ECHO Starting ISO Download...
) || (
ECHO. & ECHO Resuming ISO Download...
)
) ELSE (
ECHO. & ECHO Starting ISO Download...
)
"%TempDL%\aria2c.exe" --continue=true --summary-interval=0 --file-allocation=none --auto-file-renaming=false --max-connection-per-server=5 "!link!" -o Win1%VERSION%_Eng_x64.iso
POWERSHELL -nop -c "Dismount-DiskImage ""%~dp0Win1%VERSION%_Eng_x64.iso""">nul
MOVE /Y "Win1%VERSION%_Eng_x64.iso" "%~dp0">nul && (ECHO Download completed and Win1%VERSION%_Eng_x64.iso moved to %~dp0>>"%~dp0WimFix.log") || (ECHO Error moving Win1%VERSION%_Eng_x64.iso to %~dp0>>"%~dp0WimFix.log")
SET ISO="%~dp0Win1%VERSION%_Eng_x64.iso"
POPD
EXIT /b
:GETLINK
ECHO. & ECHO Requesting Download from Microsoft...
FOR /f "delims=" %%A in ('powershell -nop -ep bypass -c ".\fido.ps1 -Win 1%VERSION% -Lang Eng -Arch x64 -GetUrl"') DO SET "link=%%A"
ECHO !link!>download.1%VERSION%.link
EXIT /b
:ADDUNSUPPORTEDCMD
(
ECHO @^(set '^(=^)^|^|' ^<# lean and mean cmd / powershell hybrid #^> @'
ECHO ::# Get Windows 11 on 'Unsupported' PCs via Windows Update or Mounted ISO - AveYo 2023.07.14
ECHO @ECHO OFF ^& TITLE Allow Unsupported Windows 11 Upgrades via Windows Update or Mounted ISO
ECHO if /i "%%~f0" neq "%%ProgramData%%\AllowUpgrades\AllowUpgrades.cmd" goto setup
ECHO powershell -win 1 -nop -c ";"
ECHO set CLI=%%*^& set SOURCES=%%SystemDrive%%\$WINDOWS.~BT\Sources^& set MEDIA=.^& set MOD=CLI^& set PRE=WUA^& set /a VER=11
ECHO if not defined CLI ^(exit /b^) else if not exist %%SOURCES%%\SetupHost.exe ^(exit /b^)
ECHO if not exist %%SOURCES%%\WindowsUpdateBox.exe mklink /h %%SOURCES%%\WindowsUpdateBox.exe %%SOURCES%%\SetupHost.exe
ECHO reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /f /v DisableWUfBSafeguards /d 1 /t reg_dword
ECHO reg add HKLM\SYSTEM\Setup\MoSetup /f /v AllowUpgradesWithUnsupportedTPMorCPU /d 1 /t reg_dword
ECHO reg add HKCU\SOFTWARE\Microsoft\PCHC /f /v UpgradeEligibility /d 1 /t reg_dword
ECHO set OPT=/Compat IgnoreWarning /MigrateDrivers All /Telemetry Disable
ECHO set /a restart_application=0x800705BB ^& ^(call set CLI=%%%%CLI:%%1 =%%%%^)
ECHO set /a incorrect_parameter=0x80070057 ^& ^(set SRV=%%CLI:/Product Client =%%^)
ECHO set /a launch_option_error=0xc190010a ^& ^(set SRV=%%SRV:/Product Server =%%^)
ECHO for %%%%W in ^(%%CLI%%^) do if /i %%%%W == /PreDownload ^(set MOD=SRV^)
ECHO for %%%%W in ^(%%CLI%%^) do if /i %%%%W == /InstallFile ^(set PRE=ISO^& set "MEDIA="^) else if not defined MEDIA set "MEDIA=%%%%~dpW"
ECHO if %%VER%% == 11 for %%%%W in ^("%%MEDIA%%appraiserres.dll"^) do if exist %%%%W if %%%%~zW == 0 set AlreadyPatched=1 ^& set /a VER=10
ECHO if %%VER%% == 11 findstr /r "P.r.o.d.u.c.t.V.e.r.s.i.o.n...1.0.\..0.\..2.[2-9]" %%SOURCES%%\SetupHost.exe ^>nul 2^>nul ^|^| set /a VER=10
ECHO if %%VER%% == 11 if not exist "%%MEDIA%%EI.cfg" ^(echo;[Channel]^>%%SOURCES%%\EI.cfg ^& echo;_Default^>^>%%SOURCES%%\EI.cfg^)
ECHO if %%VER%%_%%PRE%% == 11_ISO ^(%%SOURCES%%\WindowsUpdateBox.exe /Product Server /PreDownload /Quiet %%OPT%%^)
ECHO if %%VER%%_%%PRE%% == 11_ISO ^(del /f /q %%SOURCES%%\appraiserres.dll 2^>nul ^& cd.^>%%SOURCES%%\appraiserres.dll^)
ECHO if %%VER%%_%%MOD%% == 11_SRV ^(set ARG=%%OPT%% %%SRV%% /Product Server^)
ECHO if %%VER%%_%%MOD%% == 11_CLI ^(set ARG=%%OPT%% %%CLI%%^)
ECHO %%SOURCES%%\WindowsUpdateBox.exe %%ARG%%
ECHO if %%errorlevel%% == %%restart_application%% %%SOURCES%%\WindowsUpdateBox.exe %%ARG%%
ECHO exit /b
ECHO :setup
ECHO ^>nul 2^>^&1 REG ADD HKCU\Software\Classes\.AllowUpgrade\shell\runas\command /f /ve /d "CMD /x /d /r SET \"f0=%%%%2\"& call \"%%%%2\" %%%%3"^& set _= %%*
ECHO ^>nul 2^>^&1 FLTMC^|^|^(CD.^>"%%temp%%\elevate.AllowUpgrade" ^& START "%%~n0" /high "%%temp%%\elevate.AllowUpgrade" "%%~f0" "%%_:"=""%%" & EXIT /b)
ECHO ^>nul 2^>^&1 REG DELETE HKCU\Software\Classes\.AllowUpgrade\ /f ^&^>nul 2^>^&1 DEL %%temp%%\elevate.AllowUpgrade /f
ECHO for /f "delims=:" %%%%s in ^('echo;prompt $h$s$h:^^^|cmd /d'^) do set "|=%%%%s"^&set ">>=\..\c nul&set /p s=%%%%s%%%%s%%%%s%%%%s%%%%s%%%%s%%%%s<nul&popd"
ECHO set "<=pushd "%%appdata%%"&2>nul findstr /c:\ /a" ^&set ">=%%>>%%&echo;" ^&set "|=%%|:~0,1%%" ^&set /p s=\^<nul^>"%%appdata%%\c"
ECHO set CLI=%%*^& ^(set IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options^)
ECHO wmic /namespace:"\\root\subscription" path __EventFilter where Name="AllowUnsupportedUpgrades" delete ^>nul 2^>nul ^& rem v1
ECHO reg delete "%%IFEO%%\vdsldr.exe" /f 2^>nul ^& rem v2 - v5
ECHO if /i "%%CLI%%"=="" reg query "%%IFEO%%\SetupHost.exe\0" /v Debugger ^>nul 2^>nul ^&^& goto remove ^|^| goto install
ECHO if /i "%%~1"=="install" ^(goto install^) else if /i "%%~1"=="remove" goto remove
ECHO :install
ECHO mkdir %%ProgramData%%\AllowUpgrades ^>nul 2^>nul ^& copy /y "%%~f0" "%%ProgramData%%\AllowUpgrades\AllowUpgrades.cmd" ^>nul 2^>nul
ECHO reg add "%%IFEO%%\SetupHost.exe" /f /v UseFilter /d 1 /t reg_dword ^>nul
ECHO reg add "%%IFEO%%\SetupHost.exe\0" /f /v FilterFullPath /d "%%SystemDrive%%\$WINDOWS.~BT\Sources\SetupHost.exe" ^>nul
ECHO reg add "%%IFEO%%\SetupHost.exe\0" /f /v Debugger /d "%%ProgramData%%\AllowUpgrades\AllowUpgrades.cmd" ^>nul
ECHO echo;
ECHO %%^<%%:f0 " AllowUnsupportedUpgrades "%%^>^>%% ^& %%^<%%:2f " ENABLED "%%^>^>%% ^& %%^<%%:f0 " Run again to DISABLE "%%^>%%
ECHO if /i "%%CLI%%"=="" ECHO. ^& PAUSE
ECHO exit /b
ECHO :remove
ECHO del /f /q "%%ProgramData%%\AllowUpgrades\AllowUpgrades.cmd"^>nul 2^>nul ^& rd /s /q "%%ProgramData%%\AllowUpgrades"^>nul 2^>nul
ECHO reg delete "%%IFEO%%\SetupHost.exe" /f ^>nul 2^>nul
ECHO echo;
ECHO %%^<%%:f0 " AllowUnsupportedUpgrades "%%^>^>%% ^& %%^<%%:df " DISABLED "%%^>^>%% ^& %%^<%%:f0 " Run again to ENABLE "%%^>%%
ECHO if /i "%%CLI%%"=="" ECHO. ^& PAUSE
ECHO EXIT /b
ECHO '@^); $0 = "$env:temp\AllowUnsupportedUpgrades.cmd"; ${^(=^)^|^|} -split "\r?\n" ^| out-file $0 -encoding default -force; ^& $0
ECHO # press enter
)>"%rootfolder%\AllowUnsupportedUpgrades.cmd"
EXIT /b
