# Connect to your Azure account
Connect-AzAccount

# Variables for resource details
$resourceGroupName = "myResourceGroup"
$location = "EastUS"
$vmName = "myVM"
$vmSize = "Standard_B1s"
$adminUsername = "azureuser"
$adminPassword = Read-Host -AsSecureString "Enter the VM admin password"  # Secure password input

# Create a resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a virtual network
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location `
    -Name "$vmName-vnet" -AddressPrefix "10.0.0.0/16"

# Create a subnet
$subnet = Add-AzVirtualNetworkSubnetConfig -Name "default" -AddressPrefix "10.0.0.0/24" `
    -VirtualNetwork $vnet
$vnet | Set-AzVirtualNetwork

# Create a public IP address
$publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location `
    -Name "$vmName-ip" -AllocationMethod Dynamic

# Create a network security group (NSG) and allow RDP access
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location `
    -Name "$vmName-nsg"
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name "AllowRDP" -Description "Allow RDP" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix "*" `
    -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 3389
$nsg | Add-AzNetworkSecurityRuleConfig -NetworkSecurityRule $nsgRuleRDP | Set-AzNetworkSecurityGroup

# Create a network interface card (NIC)
$nic = New-AzNetworkInterface -ResourceGroupName $resourceGroupName -Location $location `
    -Name "$vmName-nic" -PublicIpAddress $publicIp -NetworkSecurityGroup $nsg `
    -SubnetId $vnet.Subnets[0].Id

# Define the virtual machine configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize `
    | Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential (Get-Credential) `
    | Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest" `
    | Add-AzVMNetworkInterface -Id $nic.Id

# Create the virtual machine
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig
