Add-Content C:\Windows\System32\drivers\etc\hosts "10.0.42.240 pe-master pe-master.fritz.box"
Add-Content C:\Windows\System32\drivers\etc\hosts "10.0.42.241 pe-agent-win2012"
Add-Content C:\Windows\System32\drivers\etc\hosts "10.0.42.242 pe-agent-centos7"
Add-Content C:\Windows\System32\drivers\etc\hosts "10.0.42.243 pe-agent-ubuntu1604"

Set-Location $env:TEMP
[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile('https://pe-master:8140/packages/current/install.ps1', $env:TEMP + '\install.ps1')
.\install.ps1
