<#
.DESCRIPTION
Demo Code for UCS Manager showing how to add Global VLANs to FIs and assign the VLAN to a group. This code is not intended 
for production systems and could cause serious issues if run against a system without understanding the code. You should 
review this code competely before running it against any system. 

VLANS cannot be passed as an argument in this version, though the code could support this with minor changes. You must
edit this code directly to specify the VLANS as designed.

.NOTES
LICENSE
Copyright (c) 2018 Cisco and/or its affiliates.
This software is licensed to you under the terms of the Cisco Sample
Code License, Version 1.0 (the "License"). You may obtain a copy of the
License at
               https://developer.cisco.com/docs/licenses
All use of the material herein must be in accordance with the terms of
the License. All rights not expressly granted by the License are
reserved. Unless required by applicable law or agreed to separately in
writing, software distributed under the License is distributed on an "AS
IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
or implied.
.PARAMETER iGetIt
This is a fail safe designed to ensure that the script is not run accidently against a production system.
.PARAMETER ucsGroupName
This is the group that the VLANs will be assigned to.
#>

[cmdletbinding(SupportsShouldProcess=$True)]
param(
    [parameter(Mandatory=$False)][switch]$iGetIt = $False,
    [parameter(Mandatory=$False)][string]$ucsGroupName = "Test"
)

# Warn if user has not acknowledge the risk of running this script.

$Warning = @"
This script changes the VLAN configuration on a UCS domain and is not intended, as written, for any production system.
You should review and understand this script completely before running this script.  Your recieving this message because
you did not indicate that you understand the risks around running this script. If you fully understand this script, you
can bypass this and run the script by using the -iGetIt switch.
"@

if ($iGetIt -eq $false) {
    write-host "$($Warning)"
    exit
}

# If we use something like this, we can easily create sequential VLAN numbers, but only if we use susequent VLAN names that can
# be derived from the vlan ID. In this case we will create an array of 5, 6 and 7.
$a = 5..7

# Otherwise we need a more complicated array, so we use a hash table of entries
[hashtable[]]$b = @{}
$b =  @{Name="StorageVLAN"; id="2"}
$b += @{Name="MgmtVLAN";    id="3"}
$b += @{Name="vMotion";     id="4"}

# You could also use a CSV File, which can be converted to an object using convertfrom-csv and the get-content command.
# No Expample provided for that method. 

Function get-VlanByID {
    param(
        [Parameter(Mandatory=$true)][string]$id
    )
    Begin {
        Write-Verbose "     Validate if ID is present on Fabric"
    }
    process{
        $vlanResult = get-ucsvlan -id $id
        if ($vlanResult){ 
            write-Verbose "     VLAN Exists"
            return $true
        } 
        else {
            write-verbose "     VLAN Does not Exist"
            return $False
        }
    

    }
}


Function Add-GlobalVlanToFI {
    param(
        [parameter(Mandatory=$True)][string]$vlanName,
        [parameter(Mandatory=$True)][string]$vlanID
    )
    begin{
        Write-Verbose "Staring VLAN Creation process for $vlanID on fabric interconnects."
    }
    process{
        if ((get-VlanByID -Id $vlanId) -eq $False) {
            write-verbose "     VLAN creation transation starting"
            $error.Clear()
            $createVlanResult =  get-UcsLanCloud | add-ucsvlan -Name $vlanName -Id $vlanID -ErrorAction SilentlyContinue
            if ($error) {
                write-host $error[0]
                Exit
            }
            else{
                write-verbose "     VLAN Creation successfully completed"
            }
        }
        Else {
            write-Verbose "     Not creating VLAN since it already exists"
        }

    }
    end{}
}

Function Add-GlobalVlanToGroup{
    param(
        [parameter(Mandatory=$True)][string]$vlanName,
        [parameter(Mandatory=$True)][string]$groupName
    )
    begin {
        write-verbose "Starting process to add VLAN $vlanName to $groupName"
    }
    process{
        $NetGroup = get-ucslancloud | get-ucsFabricNetGroup -Name $groupName
        $NetGrpAsgnResult = $NetGroup | add-ucsFabricPooledVLAN -ModifyPresent -Name $vlanName
    }


}

$a | %{
    add-GlobalVlanToFI -VlanName "VLAN-$($_)" -vlanId "$($_)"
    add-GlobalVlanToGroup -vlanName "VLAN-$($_)" -groupName "$($ucsGroupName)"
}

$b | %{
    Add-GlobalVlanToFI -vlanName "$($_.Name)" -vlanId "$($_.id)"
    add-GlobalVlanToGroup -vlanName "$($_.Name)" -groupName "$($ucsGroupName)"

}
