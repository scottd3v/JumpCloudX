##### Command

```
## NotePad++ installer
$DownloadURL = 'https://notepad-plus-plus.org/repository/7.x/7.5.1/npp.7.5.1.Installer.x64.exe'
$FileName = 'npp.7.5.1.Installer.x64.exe' #Enter name of the file
$DownloadPath = "C:\Windows\Temp\$FileName"
                     
(New-Object System.Net.WebClient).DownloadFile($DownloadURL,$DownloadPath) #Downloads the file
                     
Start-Process  -FilePath "C:\Windows\temp\npp.7.5.1.Installer.x64.exe" -ArgumentList  "/S"
```

##### Name
Windows - Install Notepad ++

##### commandType
windows
