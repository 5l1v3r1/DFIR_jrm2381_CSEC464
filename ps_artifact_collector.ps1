#Powershell Artifact Collector

If (Test-Path "output.csv"){
	Remove-Item "output.csv"
}

New-Item -ItemType "file" -Path "output.csv"

$cur_time  = Get-Date -DisplayHint time
$time_zone = (Get-Timezone).Id

function GetUp{
    $os = Get-WmiObject win32_operatingsystem
    $up = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
    $fin =  "" + $up.Days + " days, " + $up.Hours + " hours, " + $up.Minutes + " minutes"
    return $fin
}
$uptime = GetUp

$time_info = New-Object psobject -Property @{
    Current_Time = $cur_time
    Time_Zone = $time_zone
    PC_Uptime = $uptime
}

$time_info | Format-Table Current_Time, Time_Zone, PC_Uptime -AutoSize
$time_info | Out-File -FilePath output.csv -Append

$os_info = New-Object psobject -Property @{
    Major = ([environment]::OSVersion.Version).Major
    Minor = ([environment]::OSVersion.Version).Minor
    Build = ([environment]::OSVersion.Version).Build
    Revision = ([environment]::OSVersion.Version).Revision
    Typical_Name = (Get-CimInstance Win32_OperatingSystem | Select-Object Caption).Caption
}

$os_info | Format-Table Major, Minor, Build, Revision, Typical_Name -AutoSize
$os_info | Out-File -FilePath output.csv -Append

#ram and cpu
$cpu_info = (Get-WmiObject win32_processor | Select-object Name).Name
$ram_gbs = "" + (Get-WmiObject -class Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | %{[Math]::Round(($_.sum/1GB),2)}) + "GB"
$hardware_specs = New-Object psobject -Property @{
    cpu = $cpu_info
    ram = $ram_gbs
}
$hardware_specs | Format-Table cpu, ram -AutoSize
$hardware_specs | Out-File -FilePath output.csv -Append

# HDD info
$hdd_info=Get-WmiObject -Class Win32_LogicalDisk |
Sort-Object -Property Name |
Select-Object Name, VolumeName, FileSystem, VolumeDirty, `
@{"Label"="DiskSize(GB)";"Expression"={"{0:N}" -f ($_.Size/1GB) -as [float]}} 
Get-WmiObject -Class Win32_LogicalDisk |
Sort-Object -Property Name |
Select-Object Name, VolumeName, FileSystem, VolumeDirty, `
@{"Label"="DiskSize(GB)";"Expression"={"{0:N}" -f ($_.Size/1GB) -as [float]}} |
Format-Table -AutoSize

#Hostname info
$fqdn=Get-WmiObject win32_computersystem |
Select-Object DNSHostName, Domain 

$fqdn | Out-File -FilePath output.csv -Append

Get-WmiObject win32_computersystem |
Select-Object DNSHostName, Domain |
Format-Table -AutoSize

#local users
$users_info = @()
for ($i = 1; $i -le ((Get-LocalUser | measure).Count); $i++){
$local_user_info = New-Object psobject -Property @{
    Local_Name = (Get-LocalUser).Name[$i - 1]
    SID = (Get-LocalUser).SID[$i - 1]
}
$users_info += $local_user_info}
$users_info | Format-Table Local_Name, SID -AutoSize
$users_info | Out-File -FilePath output.csv -Append

#ad users
$ad_users_info = @()
for ($i = 1; $i -le ((Get-ADUser | measure).Count); $i++){
$ad_user_info = New-Object psobject -Property @{
    Local_Name = (Get-ADUser).Name[$i - 1]
    SID = (Get-ADUser).SID[$i - 1]
    Last_Login = (Get-ADUser).LastLogonDate[$i-1]
}
$ad_users_info += $ad_user_info}
$ad_users_info | Format-Table Local_Name, SID, Last_Login -AutoSize
$ad_users_info | Out-File -FilePath output.csv -Append

#start at boot
$starts = @()
for ($i = 1; $i -le ((Get-Service | select -property name, starttype | Where-Object starttype -EQ Automatic | measure).Count); $i++){
    $serv = New-Object psobject -Property @{
    Name = (Get-Service | select -property name, starttype | Where-Object starttype -EQ Automatic).Name[$i-1]
    }
    $starts += $serv
}
for ($i = 1; $i -le ((Get-CimInstance Win32_StartupCommand | measure).Count); $i++){
    $prog = New-Object psobject -Property @{
    Name = (Get-CimInstance Win32_StartupCommand).Name[$i-1]
    REG_location = (Get-CimInstance Win32_StartupCommand).Location[$i-1]
    User = (Get-CimInstance Win32_StartupCommand).User[$i-1]
    }
    $starts += $prog
}
$starts | Format-Table Name, REG_Location, User -AutoSize
$starts | Out-File -FilePath output.csv -Append

#sch tasks
$tasks = (Get-ScheduledTask).TaskName
Get-ScheduledTask | Format-Table TaskName -AutoSize

$tasks | Out-File -FilePath output.csv -Append

#arp table
$arp_table = Get-NetNeighbor
Get-NetNeighbor | Format-Table -Autosize
$arp_table | Out-File -FilePath output.csv -Append

#macs for interfaces
$int_macs = Get-NetAdapter | select Name, MacAddress
Get-NetAdapter | select Name, MacAddress | Format-Table -Autosize
$int_macs | Out-File -FilePath output.csv -Append

#routing table
$route_table = Get-NetRoute
Get-NetRoute| Format-Table -Autosize
$route_table | Out-File -FilePath output.csv -Append

#interface_ips
$inter_ips = Get-NetIPAddress | select interfacealias, IPAddress
Get-NetIPAddress | select interfacealias, IPAddress| Format-Table -Autosize
$inter_ips | Out-File -FilePath output.csv -Append

#server_info
$dns_dhcp_serv = (Get-WmiObject -class win32_NetworkAdapterConfiguration) | Where-Object DHCPEnabled -EQ True| select Description, DHCPServer, DNSServerSearchOrder 
(Get-WmiObject -class win32_NetworkAdapterConfiguration) | Where-Object DHCPEnabled -EQ True| select Description, DHCPServer, DNSServerSearchOrder | Format-Table -Autosize
$dns_dhcp_serv | Out-File -FilePath output.csv -Append

#def_gateway
$def_gw = (Get-WmiObject -class win32_NetworkAdapterConfiguration) | select Description, DefaultIPGateway
(Get-WmiObject -class win32_NetworkAdapterConfiguration) | select Description, DefaultIPGateway | Format-Table -Autosize
$def_gw | Out-File -FilePath output.csv -Append

#active conns
Write-Host "TCP Connections: "
$tcp_conns = Get-NetTCPConnection
Get-NetTCPConnection | Format-Table -Autosize
$tcp_conns | Out-File -FilePath output.csv -Append
Write-Host "UDP Connections: "
$udp_conns = Get-NetUDPEndpoint
Get-NetUDPEndpoint
$udp_conns | Out-File -FilePath output.csv -Append

#dns cache
$dns_cache = Get-DnsClientCache
Get-DnsClientCache |Format-Table -AutoSize
$dns_cache | Out-File -FilePath output.csv -Append

#Network Shares
$net_shares = Get-SmbShare
Get-SmbShare | Format-Table -AutoSize
$net_shares | Out-File -FilePath output.csv -Append

#Printers
$printers = Get-Printer
Get-Printer | Format-Table -AutoSize
$printers | Out-File -FilePath output.csv -Append

#install progs
$progs = Get-WmiObject -class win32_product
Get-WmiObject -class win32_product | Format-Table -AutoSize
$progs | Out-File -FilePath output.csv -Append

#procs
$procs = Get-Process -IncludeUserName
Get-Process -IncludeUserName | Format-Table -AutoSize
$procs | Out-File -FilePath output.csv -Append

#drivers
#$drivers = Get-WindowsDriver -Online -All
#Get-WindowsDriver -Online -All | Format-Table -AutoSize

#User Files:
Write-Host "User Files: "
foreach($user in (Get-LocalUser | Where-Object Enabled -EQ True)){
$files = @()
$n = $user.Name
Write-Host ""+$n+"'s Files: "
$p = "C:/Users/"+$n+"/Documents"
$docs = Get-ChildItem -Path $p -Recurse | select Name
$files += $docs
$p = "C:/Users/"+$n+"/Downloads"
$downs = Get-ChildItem -Path $p -Recurse | select Name
$files += $downs
$files | Format-Table -AutoSize
$files | Out-File -FilePath output.csv -Append
}


#Get all services:
$servs = Get-Service
Get-Service | Format-Table -AutoSize
$servs | Out-File -FilePath output.csv -Append

#Get Background Tasks:
$backGrnds = Get-AppBackgroundTask
Get-AppBackgroundTask | Format-Table -AutoSize
$backGrnds | Out-File -FilePath output.csv -Append

#Get Firewall Rules:
$fw_rules = Get-NetFirewallRule | Select Name, Enabled, Direction, Action, Description
Get-NetFirewallRule | Select Name, Enabled, Direction, Action, Description | Format-Table -AutoSize
$fw_rules | Out-File -FilePath output.csv -Append


$ifEmail = Read-Host -Prompt "Email results? [y/n]: "


if( $ifEmail -eq "y"){
    $From = Read-Host -Prompt "From: "
    $To = Read-Host -Prompt "To: "
    $Attachment = "output.csv"
    $Subject = "Forensics Csv"
    $Body = "Attached is the Csv file."
    $SMTPServer = "smtp.gmail.com"
    $SMTPPort = "587"
    Send-MailMessage -From $From -to $To -Subject $Subject `
    -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl `
    -Credential (Get-Credential) -Attachments $Attachment
}
