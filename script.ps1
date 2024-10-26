# Step 1: Create a new resource group
az group create --name RG2VM --location centralus

# Step 2: 
az vm create --resource-group RG2VM --name winserver --image win2016datacenter --admin-username azureuser1
