# Win-11-Download-Prep-Tool<br>
Downloads the latest Win 11 x64 ISO direct from MS - Then SysPreps each index, removing: Network requirements during install, TPM requirements, and RAM requirements. In addition to turning off S-Mode *SecureBoot may need to be disabled as well for S-Mode*<br>
<br>
Credit to:<br>
P. Batard - <a href="https://github.com/pbatard/Fido">https://github.com/pbatard/Fido</a><br>
Wimlib-Imagex - <a href="https://wimlib.net">https://wimlib.net</a><br>
Aria2c - <a href="https://github.com/aria2/aria2">https://github.com/aria2/aria2</a><br>
7zip - <a href="https://www.7-zip.org/">https://www.7-zip.org/</a><br>
wikijim - <a href="https://github.com/wikijm/PowerShell-AdminScripts/blob/master/Miscellaneous/New-IsoFile.ps1">https://github.com/wikijm/PowerShell-AdminScripts/blob/master/Miscellaneous/New-IsoFile.ps1</a><br>
Helge Klein - <a href="https://helgeklein.com/setacl/">https://helgeklein.com/setacl/</a><br>
AveYo - <a href="https://github.com/AveYo/MediaCreationTool.bat/blob/main/bypass11/Skip_TPM_Check_on_Dynamic_Update.cmd">https://github.com/AveYo/MediaCreationTool.bat/blob/main/bypass11/Skip_TPM_Check_on_Dynamic_Update.cmd</a></br>
<br>
Additional Changes to Win 11 ISO:<br>
<br>
Allows in place upgrade on live unsupported system (From mounted ISO)<br>
Enable Legacy F8 Boot Menu<br>
Disable UAC<br>
Classic Context Menus<br>
Decrease Space Between Items (Compact View)<br>
Show Hidden Files<br>
Show File Extensions<br>
<br>
Note: Running from UNC paths is currently not supported.<br>
<br>
Instructions:<br>
1.) Double click the tool to download a new ISO directly from Microsoft and prep the image. <br>
The final ISO will appear in the same folder you ran the script from.<br>
<br>
--Alternatively--<br>
You can drop an existing Win11 ISO onto the script using the mouse drag-and-drop. Doing this will skip the download and prep the ISO you provide. The script will rebuild the ISO in its original location.<br>
<br>
How does it work?<br>
<br>
The script first checks to see if it is running as administrator, if so it continues, if not it requests admin rights (if you already have rights it will
elevate itself.) It checks to see if you Dropped a file onto it, or if you just executed it without a dropped file. If you dropped an existing ISO on the
script, the ISO download will be skipped, it will create a temp folder in ProgramData, and download 7zip, Wimlib, and SetACL only with powershell's Invoke-WebRequest
command. If you did NOT drop drop an ISO onto the script it will use powershell to download the above + Aria2c and Fido from Git, it runs CLI on Fido 
to fetch a fresh link from MS. The script will preserve the MS download link for up to 24hours and re-use it to avoid spamming MS download servers with requests. 
The link can be re-used as many times as possible until it expires(24hrs) at which point the script will see it has expired and ask for a new one. It will then 
begin the ISO download directly from Microsoft. Download resume is enabled. If the script is closed during the download, you can re-open the script and the 
download will pick up where it left off (the script will resume for up to 72hrs only to avoid version mismatch, if a partial download remains after 72 hours 
it will be removed and a new ISO will be requested.). Once the download is complete the ISO is mounted with powershell, and extracted to its own temp folder in 
ProgramData, then unmounted. Wimlib-Imagex is then used to extract the registry hives from each index (Edition), make changes, then inject the updated registry 
hives back into the Windows image, until all indexes are updated. Once the Windows image has been updated the script downloads the "New-IsoFile.ps1" powershell 
function from Git and appends the function with the appropriate commands to re-author the ISO with the new image. A CMD script is placed at the root of the ISO to
allow upgrades on unsupported machines via mounted ISO. If the script completes it cleans up after itself, leaving only the download link to be used if it is run 
again within 24hrs. And of course the ISO! ;) If it does not complete, the partial downloaded files and links will remain in ProgramData and be referenced the next
time the script is run.
