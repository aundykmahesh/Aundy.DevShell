function Get-PublicIp {
    return Invoke-WebRequest -uri "http://ifconfig.me/ip" | Select-Object -ExpandProperty Content
}
