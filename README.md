# Win-11-Download-Prep-Tool<br>
<b>Downloads the latest Win 11 x64 ISO direct from MS - Then SysPreps each index, removing: Network requirements during install, TPM requirements, and RAM requirements. In addition to turning off S-Mode (SecureBoot may need to be disabled as well)<b><br>
<br>

<b>Credit to:</b><br>
P. Batard - <a href="https://github.com/pbatard/Fido">https://github.com/pbatard/Fido</a><br>
Wimlib-Imagex - <a href="https://wimlib.net">https://wimlib.net</a><br>
Aria2c - <a href="https://github.com/aria2/aria2">https://github.com/aria2/aria2</a><br>
7zip - <a href="https://www.7zip.org">https://www.7zip.org</a><br>
wikijim - <a href="https://github.com/wikijm/PowerShell-AdminScripts/blob/master/Miscellaneous/New-IsoFile.ps1">https://github.com/wikijm/PowerShell-AdminScripts/blob/master/Miscellaneous/New-IsoFile.ps1</a><br>

Additional Changes to Win 11 ISO:<br>

Disable UAC<br>
Classic Context Menus<br>
Decrease Space Between Items (Compact View)<br>
Show Hidden Files<br>
Show File Extensions<br>
<br>
Note: Running from UNC paths is currently not supported.<br>
<br>
<br>
<b>Instructions:</b><br>
<b>1.)</b> Double click the tool to download a new ISO directly from Microsoft and prep the image. <br>
<b>*</b>The final ISO will appear in the same folder you ran the script from.<br>

<b>--Alternatively--</b><br>
You can drop an existing Win11 ISO onto the script using the mouse drag-and-drop. Doing this will skip the download and prep the ISO you provide.<br>
<b>*</b>The script will rebuild the ISO in its original location.<br>
