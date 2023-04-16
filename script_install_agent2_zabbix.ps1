<#
.SYNOPSIS
    This scrpit install a zabbix agent 2 on a remote computer.

.DESCRIPTION
    This script to work properly, the computer where it will be executed, must contain the "C:\zabbix_agent2" with the file "zabbix_agent2-6.4.1-windows-amd64-openssl.msi"
    You can download this file in: https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.1/zabbix_agent2-6.4.1-windows-amd64-openssl.msi or you can access Zabbix website and do it.
    It is necessary to change the server IP in line 44, "SERVER=172.16.20.200" to your zabbix server ip.
    You need admin profile to run this code properly
   
.NOTES
    Authors:  Flavio M. S. Amorim, Rossano S. Bernabé
    Version: 1.0.0
#>


# Function checks remote services
function Func_CheckService {

    # Checks status of services: WinRM, RpcSs, RpcEptMapper
    $WinRM = Get-Service -Name WinRM -ComputerName $RemoteComputer | Select-Object -ExpandProperty status
    if ($WinRM -like 'Stopped'){
        Get-Service -Name WinRM -ComputerName $RemoteComputer | Start-Service}

    $RpcSs = Get-Service -Name RpcSs -ComputerName $RemoteComputer | Select-Object -ExpandProperty status
    if ($RpcSs -like 'Stopped'){
        Get-Service -Name RpcSs -ComputerName $RemoteComputer | Start-Service}

    $RpcEptMapper = Get-Service -Name RpcEptMapper -ComputerName $RemoteComputer | Select-Object -ExpandProperty status
    if ($RpcEptMapper -like 'Stopped'){
        Get-Service -Name RpcEptMapper -ComputerName $RemoteComputer | Start-Service}                     

}


# Function install and configure Zabbix agent on remote computer
function Func_InstallAgent {

    Enter-PSSession -ComputerName $RemoteComputer 
    
    Invoke-Command -Session $Session -ScriptBlock {

        Set-Location "C:\zabbix_agent2"

        Start-Process msiexec -ArgumentList "/i zabbix_agent2-6.4.1-windows-amd64-openssl.msi SERVER=172.16.20.200 LISTENPORT=10050 HOSTNAME=$env:computername.$env:userdnsdomain /qn" -NoNewWindow -Wait
      
        Restart-Service -Name 'Zabbix Agent 2'
    
        Remove-Item -Path "C:\zabbix_agent2" -Recurse -Force

    }

    Exit-PSSession

    Disconnect-PSSession -Name WinRM*
   
}


# Get computer name
$RemoteComputer = Read-Host "Enter computer name:"

# Call function check service
Func_CheckService 

# Set a new session with a remote computer
$Session = New-PSSession -ComputerName $RemoteComputer

# Copy the local fagent2 to remote computer
Copy-Item "C:\zabbix_agent2" -Destination "C:\" -ToSession $Session -Recurse -Force

# Call function install agent
Func_InstallAgent
