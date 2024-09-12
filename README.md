# WorkspaceConfigureScript
Script to install prerequisites for a new workspace

```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Leuconoe/WorkspaceConfigureScript/main/WorkspaceConfigureScript.ps1" -UseBasicP)
```


```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
$url = "https://raw.githubusercontent.com/Leuconoe/WorkspaceConfigureScript/main/WorkspaceConfigureScript.ps1"
$localPath = "$env:TEMP\script.ps1"

Invoke-WebRequest -Uri $url -OutFile $localPath
```
