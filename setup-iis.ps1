
$hostName = "jcapriotti.github.io.local"
$hostsLocation = "$env:windir\System32\drivers\etc\hosts"
$newHostEntry = "`n127.0.0.1`t$hostName"
$path = (Get-Item -Path ".\" -Verbose).FullName


New-WebSite -Name "jcapriotti.github.io" -Port 80 -PhysicalPath $path -HostHeader $hostName
Add-Content -Path $hostsLocation -Value $newHostEntry
