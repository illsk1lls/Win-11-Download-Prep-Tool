@ECHO OFF
TITLE Windows 11 - Download and System Prep Tool
>nul 2>&1 REG add HKCU\Software\classes\.Admin\shell\runas\command /f /ve /d "cmd /x /d /r SET \"f0=%%2\"& call \"%%2\" %%3"& SET _= %*
>nul 2>&1 FLTMC|| IF "%f0%" neq "%~f0" (CD.>"%ProgramData%\runas.Admin" & START "%~n0" /high "%ProgramData%\runas.Admin" "%~f0" "%_:"=""%" & EXIT /b)
>nul 2>&1 REG delete HKCU\Software\classes\.Admin\ /f
>nul 2>&1 DEL "%ProgramData%\runas.Admin" /f /q
SET ISO=%1
SET currentindex=1
SET "rootfolder=%ProgramData%\TempSysPrep"
SET "folder=%rootfolder%\sources"
SET "TempDL=%ProgramData%\TempDL"
ECHO. & ECHO Getting Ready, please wait ...
IF [%1]==[] (
CALL :DOWNLOADISO
) ELSE (
CALL :DOWNLOADTOOLS
POPD & POPD
)
SET ISO=%ISO:^=^^%
SET ISO=%ISO:&=^&%
SET ISO=%ISO:(=^(%
SET ISO=%ISO:)=^)%
ECHO Started processing ISO/WIM on %date% at %time%>"%~dp0WimFix.log"
CALL :XBUTTON false
TITLE Mounting/Extracting ISO
POWERSHELL "Mount-DiskImage ""%ISO%""">>"%~dp0WimFix.log"
FOR /f "tokens=3 delims=\:" %%d IN ('reg query hklm\system\mounteddevices ^| findstr /c:"5C003F00" ^| findstr /v "{.*}"') do (  
IF EXIST "%%d:\sources\install.wim" SET SOURCE=%%d
)
IF NOT EXIST "%SOURCE%:\sources\install.wim" ECHO. & ECHO Incompatible ISO Detected!! & ECHO. & PAUSE & EXIT /b
IF EXIST "%rootfolder%" RD "%rootfolder%" /s /q>>"%~dp0WimFix.log"
MD "%mountdir%">>"%~dp0WimFix.log"
CLS & ECHO. & ECHO Getting Ready, please wait...& ECHO. & ECHO Extracting ISO...
XCOPY "%SOURCE%:\" "%rootfolder%\" /E /H /C /I /Y>>"%~dp0WimFix.log"
POWERSHELL "Dismount-DiskImage ""%ISO%""">>"%~dp0WimFix.log"
PUSHD "%folder%"
SETLOCAL ENABLEDELAYEDEXPANSION
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
REG load HKLM\tmp_software "%reversepath%/%currentindex%\software">>"%~dp0WimFix.log"
REG load HKLM\tmp_system "%reversepath%/%currentindex%\system">>"%~dp0WimFix.log"
REG load HKU\tmp_default "%reversepath%/%currentindex%\ntuser.dat">>"%~dp0WimFix.log"
REG add HKLM\tmp_software\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add HKLM\tmp_software\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f>>"%~dp0WimFix.log"
REG add HKLM\tmp_system\ControlSet001\Control\CI\Policy /v SkuPolicyRequired /t REG_DWORD /d 0 /f>>"%~dp0WimFix.log"
REG add HKLM\tmp_system\Setup\MoSetup /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add HKLM\tmp_system\Setup\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add HKLM\tmp_system\Setup\LabConfig /v BypassSecureBoot /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add HKLM\tmp_system\Setup\LabConfig /v BypassRAMCheck /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add HKU\tmp_default\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32 /ve /f>>"%~dp0WimFix.log"
REG add HKU\tmp_default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v UseCompactMode /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add HKU\tmp_default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v Hidden /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
REG add HKU\tmp_default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v HideFileExt /t REG_DWORD /d 0 /f>>"%~dp0WimFix.log"
REG unload HKLM\tmp_software>>"%~dp0WimFix.log"
REG unload HKLM\tmp_system>>"%~dp0WimFix.log"
REG unload HKU\tmp_default>>"%~dp0WimFix.log"
ECHO.
"%TempDL%\wimlib-imagex.exe" update install.wim %currentindex% --command="add "%reversepath%/%currentindex%/SOFTWARE" Windows/System32/config/SOFTWARE"
ECHO.
"%TempDL%\wimlib-imagex.exe" update install.wim %currentindex% --command="add "%reversepath%/%currentindex%/SYSTEM" Windows/System32/config/SYSTEM"
ECHO.
"%TempDL%\wimlib-imagex.exe" update install.wim %currentindex% --command="add "%reversepath%/%currentindex%/ntuser.dat" Users/Default/ntuser.dat"
ECHO.
RD "%folder%\%currentindex%" /s /q>>"%~dp0WimFix.log"
) ELSE (
ENDLOCAL
GOTO FINALIZE
)
SET /a currentindex+=1
GOTO APPLY
:FINALIZE
TITLE Please Wait...
POPD
ECHO. & ECHO Updating ISO, please wait...
CALL :MAKEISO %ISO%
DEL "%ProgramData%\MakeIso.ps1" /f /q>nul
ECHO Completed processing ISO/WIM on %date% at %time%>>"%~dp0WimFix.log"
RD "%rootfolder%" /s /q>>"%~dp0WimFix.log"
RD "%TempDL%" /S /Q>>"%~dp0WimFix.log"
TITLE Process Complete!
ECHO. & ECHO Process Complete! ISO Updated! & ECHO.
CALL :XBUTTON true
PAUSE
EXIT /b
:XBUTTON
POWERSHELL -nop -c "(Add-Type -PassThru 'using System; using System.Runtime.InteropServices; namespace CloseButtonToggle { internal static class WinAPI { [DllImport(\"kernel32.dll\")] internal static extern IntPtr GetConsoleWindow(); [DllImport(\"user32.dll\")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool DeleteMenu(IntPtr hMenu, uint uPosition, uint uFlags); [DllImport(\"user32.dll\")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool DrawMenuBar(IntPtr hWnd); [DllImport(\"user32.dll\")] internal static extern IntPtr GetSystemMenu(IntPtr hWnd, [MarshalAs(UnmanagedType.Bool)]bool bRevert); const uint SC_CLOSE = 0xf060; const uint MF_BYCOMMAND = 0; internal static void ChangeCurrentState(bool state) { IntPtr hMenu = GetSystemMenu(GetConsoleWindow(), state); DeleteMenu(hMenu, SC_CLOSE, MF_BYCOMMAND); DrawMenuBar(GetConsoleWindow()); } } public static class Status { public static void Disable() { WinAPI.ChangeCurrentState(%1); } } }')[-1]::Disable()"
EXIT /b
:MAKEISO
TITLE Rebuilding ISO
SET ISO=%ISO:^=%
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://raw.githubusercontent.com/wikijm/PowerShell-AdminScripts/master/Miscellaneous/New-IsoFile.ps1 -o '%ProgramData%\MakeIso.ps1'"
ECHO $source_dir = "%rootfolder%">>"%ProgramData%\MakeIso.ps1"
ECHO get-childitem "$source_dir" ^| New-ISOFile -force -path %ISO% -BootFile %rootfolder%\efi\microsoft\boot\efisys.bin -Title "Win11-ReadyToInstall">>"%ProgramData%\MakeIso.ps1"
POWERSHELL -executionpolicy unrestricted -file "%ProgramData%\MakeIso.ps1">nul
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
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://www.7-zip.org/a/7zr.exe -o '7zr.exe'"; "Invoke-WebRequest -Uri https://www.7-zip.org/a/7z2300-extra.7z -o '7zExtra.7z'"; "Invoke-WebRequest -Uri https://wimlib.net/downloads/wimlib-1.14.1-windows-x86_64-bin.zip -o 'wimlib.zip'"
7zr.exe e -y 7zExtra.7z>nul & 7za.exe e -y wimlib.zip libwim-15.dll -r -o..>nul & 7za.exe e -y wimlib.zip wimlib-imagex.exe -r -o..>nul
EXIT /b
:DOWNLOADISO
SETLOCAL ENABLEDELAYEDEXPANSION
CALL :DOWNLOADTOOLS
TITLE Getting Windows 11
CLS
ECHO. & ECHO Preparing for ISO Download...
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0-win-64bit-build1.zip -o 'Aria2c.zip'"; "Invoke-WebRequest -Uri https://raw.githubusercontent.com/pbatard/Fido/master/Fido.ps1 -o 'Fido.ps1'"
7za.exe e -y Aria2c.zip Aria2c.exe -r -o..>nul & MOVE Fido.ps1 ..>nul & POPD
IF EXIST download.link (
FORFILES /d -1 /m "download.link" >NUL 2>NUL && (
DEL download.link
CALL :GETLINK
) || (
ECHO. & ECHO Re-Using Existing Download Link...
SET /p link=<download.link
)
) ELSE (
CALL :GETLINK
)
ECHO. & ECHO Starting ISO Download...
"%TempDL%\aria2c.exe" --summary-interval=0 --file-allocation=falloc --max-connection-per-server=5 "!link!" -o Win11_Eng_x64.iso
MOVE /Y "Win11_Eng_x64.iso" "%~dp0">nul
SET ISO="%~dp0Win11_Eng_x64.iso"
POPD
ENDLOCAL
EXIT /b
:GETLINK
ECHO. & ECHO Requesting Download from Microsoft...
FOR /f "delims=" %%A in ('powershell -nop -executionpolicy unrestricted -c ".\fido.ps1 -Win 11 -Lang Eng -Arch x64 -GetUrl"') DO SET "link=%%A"
ECHO !link!>download.link
EXIT /b