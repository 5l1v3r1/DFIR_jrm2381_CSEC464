Write-Host "Press enter on a blank entry to finish"
$comps = @()
do{
    $inp = Read-Host "Enter an IP address to connect to"
    $comps += $inp
} while ($inp -ne "")

foreach($ip in $comps){
    Invoke-Command -ComputerName $ip -FilePath C:\path\to\script
}