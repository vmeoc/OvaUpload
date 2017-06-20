###################################
<#Created By Vincent Meoc
Purpose: easily upload OVA VM to vSPhere during POC
Usage: OVAUpload.ps1 -ovfpath <ovfpath> -vmname <vmname> -IP <IP> -OVAType <vRA|LI|vROps|vRB>
#>


param (
[string]$ovfpath = $(throw "-ovfpath is required."),
[string]$vmname = $(throw "-vmname is required."),
[string]$IP = $(throw "-IP is required."),
[string]$OVAType = $(throw "-OVAType {vRA|LI|vROps|vRB} is required.")
)

#Credentials to connect to vCenter
$vCenter="vcsa-01a.corp.local"
$vCenterLogin="administrator@vsphere.local"
$vCenterPasswd="VMware1!"
$Cluster="Cluster site A"

#Settings to set in each deployment
#Network settings
$Gateway="192.168.110.1"
$Domain="My.domain.com"
$SearchPath="My.domain.com"
$DNS="192.168.110.10"
$Netmask="255.255.255.0"
$NetworkMapping="VM Network"
$Protocol="IPv4"

#User/pass
$rootPassd="VMware1!"

#Misc:
$Telemetry="False"
$SSH="True"
$Currency="EUR - Euro"
$Serverenabled="True"
$Hostname = ($vmname + "." + $Domain)
$IPV6 = "False"
$DeploymentOption= "Small"
$Timezone="Europe/Paris"

##########################################Connection to vCenter#################################

connect-viserver $vCenter -user $vCenterLogin -Password $vCenterPasswd
write-host ("Connected to vCenter")
$myhost=Get-cluster $cluster | Get-VMHost | Where {$_.PowerState –eq “PoweredOn” –and $_.ConnectionState –eq “Connected”} | Get-Random
write-host ("Destination host is " + $myhost)
$datastore = $myhost | get-Datastore | Sort FreeSpaceGB –Descending | Select –first 1
write-host ("Destination Datatstore is " + $datastore)
$ovfconfig=Get-OvfConfiguration $ovfpath


#######################################Settings for vRealize Business###############################

$vRBconfig = @{
"vami.gateway.vRealize_Business_for_Cloud"=$Gateway
"NetworkMapping.Network_1.Value"=$NetworkMapping
"vami.domain.vRealize_Business_for_Cloud"=$Domain
"itfm_telemetry_enabled"=$Telemetry
"vami.searchpath.vRealize_Business_for_Cloud"=$SearchPath
"itfm_root_password"=$rootPassd
"IpAssignment.IpProtocol"=$Protocol
"vami.DNS.vRealize_Business_for_Cloud"=$DNS
"itfm_server_enabled"=$Serverenabled
"itfm_ssh_enabled"=$SSH
"vami.netmask0.vRealize_Business_for_Cloud"=$Netmask
"itfm_currency"=$Currency
"vami.ip0.vRealize_Business_for_Cloud"=$IP}


######################################Settings for vRealize Automation##############################

$vRAConfig = @{
"va-ssh-enabled"= $SSH
"vami.searchpath.VMware_vRealize_Appliance" = $Domain
"varoot-password" = $rootPassd
"vami.gateway.VMware_vRealize_Appliance" = $Gateway
"vami.ip0.VMware_vRealize_Appliance" = $IP
"vami.domain.VMware_vRealize_Appliance" = $Domain
"vami.hostname" = $Hostname
"vami.netmask0.VMware_vRealize_Appliance" = $Netmask
"vami.DNS.VMware_vRealize_Appliance" = $DNS
"NetworkMapping.Network 1" = $NetworkMapping
"IpAssignment.IpProtocol" = $Protocol}

######################################Settings for vRealize Operations##############################

$vROpsConfig = @{
"vami.DNS.vRealize_Operations_Manager_Appliance"= $DNS
"vami.netmask0.vRealize_Operations_Manager_Appliance" = $Netmask
"vami.gateway.vRealize_Operations_Manager_Appliance" = $Gateway
"forceIpv6"= $False
"vamitimezone" = $Timezone
#"DeploymentOption" = $DeploymentOption
"vami.ip0.vRealize_Operations_Manager_Appliance" = $IP
"NetworkMapping.Network 1" = $NetworkMapping
"IpAssignment.IpProtocol" = $Protocol
}

########################################################################################################
write-host("Summary of the settings ")
$vROpsconfig | ft –autosize

switch ($OVAType)
    {
        vRA {Import-VApp –Source $ovfpath –OvfConfiguration $VRAconfig –Name $vmname –VMHost $myhost –Datastore $datastore –DiskStorageFormat Thin}
        vRB {Import-VApp –Source $ovfpath –OvfConfiguration $LIconfig –Name $vmname –VMHost $myhost –Datastore $datastore –DiskStorageFormat Thin}
        vROps {Import-VApp –Source $ovfpath –OvfConfiguration $VROpsconfig –Name $vmname –VMHost $myhost –Datastore $datastore –DiskStorageFormat Thin}
}
