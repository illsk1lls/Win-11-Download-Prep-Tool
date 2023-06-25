@ECHO OFF
>nul 2>&1 reg add hkcu\software\classes\.Admin\shell\runas\command /f /ve /d "cmd /x /d /r SET \"f0=%%2\"& call \"%%2\" %%3"& SET _= %*
>nul 2>&1 fltmc|| IF "%f0%" neq "%~f0" (CD.>"%ProgramData%\runas.Admin" & START "%~n0" /high "%ProgramData%\runas.Admin" "%~f0" "%_:"=""%" & EXIT /b)
>nul 2>&1 reg delete hkcu\software\classes\.Admin\ /f
>nul 2>&1 DEL "%ProgramData%\runas.Admin" /f /q
SET ISO=%1
SET /a currentindex=1
SET "rootfolder=%ProgramData%\FixWindowsDisc"
SET "folder=%rootfolder%\sources"
SET "mountdir=%folder%\current"
SETLOCAL ENABLEDELAYEDEXPANSION
ECHO. & ECHO Please wait, getting ready...
ECHO. Started processing ISO/WIM on %date% at %time%>"%~dp0WimFix.log"
:PROPERUSE
IF [%1]==[] GOTO IMPROPERUSE
CALL :DISABLEX
POWERSHELL "Mount-DiskImage ""%ISO%""">>"%~dp0WimFix.log"
FOR /f "tokens=3 delims=\:" %%d IN ('reg query hklm\system\mounteddevices ^| findstr /c:"5C003F00" ^| findstr /v "{.*}"') do (  
IF EXIST "%%d:\sources\install.wim" SET SOURCE=%%d
)
IF NOT EXIST "%SOURCE%:\sources\install.wim" ECHO. & ECHO Windows Installation Disk Not Detected!! & ECHO. & PAUSE & EXIT /b
IF EXIST "%rootfolder%" RD "%rootfolder%" /s /q>>"%~dp0WimFix.log"
MD "%mountdir%">>"%~dp0WimFix.log"
ECHO. & ECHO Extracting ISO...
XCOPY "%SOURCE%:\" "%rootfolder%\" /E /H /C /I /Y>>"%~dp0WimFix.log"
POWERSHELL "Dismount-DiskImage ""%ISO%""">>"%~dp0WimFix.log"
PUSHD %folder%
FOR /F "usebackq tokens=3" %%i IN (`dism /get-wiminfo /wimfile:"%folder%\install.wim"`) DO (
SET index=%%i
SET index=!index:,=!
IF !index! LSS 99 SET totalindex=!index!
)
:APPLY
CLS
IF %currentindex% leq %totalindex% (
TITLE Applying Settings to WIM ^(Index %currentindex% of %totalindex%^)
ECHO. & ECHO Working on Index %currentindex%...
DISM /mount-image /imagefile:"install.wim" /index:%currentindex% /mountdir:"%mountdir%"
reg load HKLM\tmp_software %mountdir%\Windows\System32\config\software>>"%~dp0WimFix.log"
reg load HKEY_USERS\tmp_DEFAULT %mountdir%\Users\Default\ntuser.dat>>"%~dp0WimFix.log"
reg add HKLM\tmp_software\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
reg ADD HKEY_USERS\tmp_DEFAULT\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32 /t REG_SZ /d "" /f>>"%~dp0WimFix.log"
reg ADD HKEY_USERS\tmp_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v UseCompactMode /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
reg ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f>>"%~dp0WimFix.log"
reg ADD HKEY_USERS\tmp_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v Hidden /t REG_DWORD /d 1 /f>>"%~dp0WimFix.log"
reg ADD HKEY_USERS\tmp_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v HideFileExt /t REG_DWORD /d 0 /f>>"%~dp0WimFix.log"
reg unload HKLM\tmp_software>>"%~dp0WimFix.log"
reg unload HKEY_USERS\tmp_DEFAULT>>"%~dp0WimFix.log"
DISM /unmount-image /mountdir:"%mountdir%" /Commit
) ELSE (
RD "%mountdir%" /s /q>>"%~dp0WimFix.log"
GOTO FINALIZE
)
SET /a currentindex+=1
GOTO APPLY
:FINALIZE
POPD
ECHO. & ECHO Updating ISO...
CALL :MAKEISO %ISO%
DEL "%ProgramData%\MakeIso.ps1" /f /q>nul
ECHO. Completed processing ISO/WIM on %date% at %time%>>"%~dp0WimFix.log"
RD "%rootfolder%" /s /q>>"%~dp0WimFix.log"
ECHO. & ECHO Complete!
PAUSE
EXIT /b
:DISABLEX
POWERSHELL -nop -c "(Add-Type -PassThru 'using System; using System.Runtime.InteropServices; namespace CloseButtonToggle { internal static class WinAPI { [DllImport(\"kernel32.dll\")] internal static extern IntPtr GetConsoleWindow(); [DllImport(\"user32.dll\")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool DeleteMenu(IntPtr hMenu, uint uPosition, uint uFlags); [DllImport(\"user32.dll\")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool DrawMenuBar(IntPtr hWnd); [DllImport(\"user32.dll\")] internal static extern IntPtr GetSystemMenu(IntPtr hWnd, [MarshalAs(UnmanagedType.Bool)]bool bRevert); const uint SC_CLOSE = 0xf060; const uint MF_BYCOMMAND = 0; internal static void ChangeCurrentState(bool state) { IntPtr hMenu = GetSystemMenu(GetConsoleWindow(), state); DeleteMenu(hMenu, SC_CLOSE, MF_BYCOMMAND); DrawMenuBar(GetConsoleWindow()); } } public static class Status { public static void Disable() { WinAPI.ChangeCurrentState(false); } } }')[-1]::Disable()"
EXIT /b
:IMPROPERUSE
CLS
ECHO.
ECHO =============================================
ECHO.
ECHO            IMPROPER USE DETECTED
ECHO.
ECHO  CLOSE THE PROGRAM AND DRAG AND DROP THE ISO 
ECHO            ONTO THE TOOL TO BEGIN
ECHO.
ECHO       THIS TOOL CANNOT BE RUN DIRECTLY
ECHO =============================================
ECHO.
ECHO.
ECHO.
PAUSE
EXIT
:MAKEISO
SETLOCAL DISABLEDELAYEDEXPANSION
ECHO function New-IsoFile>"%ProgramData%\MakeIso.ps1"
ECHO {>>"%ProgramData%\MakeIso.ps1"
ECHO [CmdletBinding(DefaultParameterSetName='Source')]Param(>>"%ProgramData%\MakeIso.ps1"
ECHO [parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true, ParameterSetName='Source')]$Source,>>"%ProgramData%\MakeIso.ps1"
ECHO [parameter(Position=2)][string]$Path = "$env:temp\$((Get-Date).ToString('yyyyMMdd-HHmmss.ffff')).iso",>>"%ProgramData%\MakeIso.ps1"
ECHO [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})][string]$BootFile = $null,>>"%ProgramData%\MakeIso.ps1"
ECHO [ValidateSet('CDR','CDRW','DVDRAM','DVDPLUSR','DVDPLUSRW','DVDPLUSR_DUALLAYER','DVDDASHR','DVDDASHRW','DVDDASHR_DUALLAYER','DISK','DVDPLUSRW_DUALLAYER','BDR','BDRE')][string] $Media = 'DVDPLUSRW_DUALLAYER',>>"%ProgramData%\MakeIso.ps1"
ECHO [string]$Title = (Get-Date).ToString("yyyyMMdd-HHmmss.ffff"),>>"%ProgramData%\MakeIso.ps1"
ECHO [switch]$Force, >>"%ProgramData%\MakeIso.ps1"
ECHO [parameter(ParameterSetName='Clipboard')][switch]$FromClipboard>>"%ProgramData%\MakeIso.ps1"
ECHO )>>"%ProgramData%\MakeIso.ps1"
ECHO Begin {>>"%ProgramData%\MakeIso.ps1"
ECHO ($cp = new-object System.CodeDom.Compiler.CompilerParameters).CompilerOptions = '/unsafe'>>"%ProgramData%\MakeIso.ps1"
ECHO if (!('ISOFile' -as [type])) {>>"%ProgramData%\MakeIso.ps1"
ECHO Add-Type -CompilerParameters $cp -TypeDefinition @'>>"%ProgramData%\MakeIso.ps1"
ECHO public class ISOFile>>"%ProgramData%\MakeIso.ps1"
ECHO {>>"%ProgramData%\MakeIso.ps1"
ECHO public unsafe static void Create^(string Path, object Stream, int BlockSize, int TotalBlocks^)>>"%ProgramData%\MakeIso.ps1"
ECHO {>>"%ProgramData%\MakeIso.ps1"
ECHO int bytes = 0;>>"%ProgramData%\MakeIso.ps1"
ECHO byte[] buf = new byte[BlockSize];>>"%ProgramData%\MakeIso.ps1"
ECHO var ptr = ^(System.IntPtr^)^(^&bytes^);>>"%ProgramData%\MakeIso.ps1"
ECHO var o = System.IO.File.OpenWrite^(Path^);>>"%ProgramData%\MakeIso.ps1"
ECHO var i = Stream as System.Runtime.InteropServices.ComTypes.IStream;>>"%ProgramData%\MakeIso.ps1"
ECHO if ^(o != null^) {>>"%ProgramData%\MakeIso.ps1"
ECHO while ^(TotalBlocks-- ^> 0^) {>>"%ProgramData%\MakeIso.ps1"
ECHO i.Read^(buf, BlockSize, ptr^); o.Write^(buf, 0, bytes^);>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO o.Flush^(^); o.Close^(^);>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO '@>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO if ($BootFile) {>>"%ProgramData%\MakeIso.ps1"
ECHO if('BDR','BDRE' -contains $Media) { Write-Warning "Bootable image doesn't seem to work with media type $Media" }>>"%ProgramData%\MakeIso.ps1"
ECHO ($Stream = New-Object -ComObject ADODB.Stream -Property @{Type=1}).Open()>>"%ProgramData%\MakeIso.ps1"
ECHO $Stream.LoadFromFile((Get-Item -LiteralPath $BootFile).Fullname)>>"%ProgramData%\MakeIso.ps1"
ECHO ($Boot = New-Object -ComObject IMAPI2FS.BootOptions).AssignBootImage($Stream)>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO $MediaType = @('UNKNOWN','CDROM','CDR','CDRW','DVDROM','DVDRAM','DVDPLUSR','DVDPLUSRW','DVDPLUSR_DUALLAYER','DVDDASHR','DVDDASHRW','DVDDASHR_DUALLAYER','DISK','DVDPLUSRW_DUALLAYER','HDDVDROM','HDDVDR','HDDVDRAM','BDROM','BDR','BDRE')>>"%ProgramData%\MakeIso.ps1"
ECHO Write-Verbose -Message "Selected media type is $Media with value $($MediaType.IndexOf($Media))">>"%ProgramData%\MakeIso.ps1"
ECHO ($Image = New-Object -com IMAPI2FS.MsftFileSystemImage -Property @{VolumeName=$Title}).ChooseImageDefaultsForMediaType($MediaType.IndexOf($Media))>>"%ProgramData%\MakeIso.ps1"
ECHO if (!($Target = New-Item -Path $Path -ItemType File -Force:$Force -ErrorAction SilentlyContinue)) { Write-Error -Message "Cannot create file $Path. Use -Force parameter to overwrite if the target file already exists."; break }>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO Process {>>"%ProgramData%\MakeIso.ps1"
ECHO if($FromClipboard) {>>"%ProgramData%\MakeIso.ps1"
ECHO if($PSVersionTable.PSVersion.Major -lt 5) { Write-Error -Message 'The -FromClipboard parameter is only supported on PowerShell v5 or higher'; break }>>"%ProgramData%\MakeIso.ps1"
ECHO $Source = Get-Clipboard -Format FileDropList>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO foreach($item in $Source) {>>"%ProgramData%\MakeIso.ps1"
ECHO if($item -isnot [System.IO.FileInfo] -and $item -isnot [System.IO.DirectoryInfo]) {>>"%ProgramData%\MakeIso.ps1"
ECHO $item = Get-Item -LiteralPath $item>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO if($item) {>>"%ProgramData%\MakeIso.ps1"
ECHO Write-Verbose -Message "Adding item to the target image: $($item.FullName)">>"%ProgramData%\MakeIso.ps1"
ECHO try { $Image.Root.AddTree($item.FullName, $true) } catch { Write-Error -Message ($_.Exception.Message.Trim() + ' Try a different media type.') }>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO End {>>"%ProgramData%\MakeIso.ps1"
ECHO if ($Boot) { $Image.BootImageOptions=$Boot }>>"%ProgramData%\MakeIso.ps1"
ECHO $Result = $Image.CreateResultImage()>>"%ProgramData%\MakeIso.ps1"
ECHO [ISOFile]::Create($Target.FullName,$Result.ImageStream,$Result.BlockSize,$Result.TotalBlocks)>>"%ProgramData%\MakeIso.ps1"
ECHO Write-Verbose -Message "Target image ($($Target.FullName)) has been created">>"%ProgramData%\MakeIso.ps1"
ECHO $Target>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO }>>"%ProgramData%\MakeIso.ps1"
ECHO $source_dir = "%rootfolder%">>"%ProgramData%\MakeIso.ps1"
ECHO get-childitem "$source_dir" ^| New-ISOFile -force -path %ISO% -BootFile %rootfolder%\efi\microsoft\boot\efisys.bin -Title "Win11-ReadyToInstall">>"%ProgramData%\MakeIso.ps1"
POWERSHELL -executionpolicy unrestricted -file "%ProgramData%\MakeIso.ps1">nul
EXIT /b
