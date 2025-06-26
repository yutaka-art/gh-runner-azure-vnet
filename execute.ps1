# 以下が設定する必要があるパラメータです
#export AZURE_LOCATION=YOUR_AZURE_LOCATION
#export SUBSCRIPTION_ID=YOUR_SUBSCRIPTION_ID
#export TENANT_ID=YOUR_TENANT_ID
#export RESOURCE_GROUP_NAME=YOUR_RESOURCE_GROUP_NAME
#export VNET_NAME=YOUR_VNET_NAME
#export SUBNET_NAME=YOUR_SUBNET_NAME
#export NSG_NAME=YOUR_NSG_NAME
#export NETWORK_SETTINGS_RESOURCE_NAME=YOUR_NETWORK_SETTINGS_RESOURCE_NAME
#export DATABASE_ID=YOUR_DATABASE_ID

# 0. 変数の設定
$AZURE_LOCATION='japaneast'
$SUBSCRIPTION_ID='99999999-XXXX-XXXX-XXXX-XXXXXXXXXXXX'         # 環境に合わせて設定してください
$TENANT_ID='99999999-XXXX-XXXX-XXXX-XXXXXXXXXXXX'               # 環境に合わせて設定してください
$RESOURCE_GROUP_NAME='rg-integrated-runner'                 # 任意の値としてください。「rg」はリソースグループの推奨される命名規則です
$VNET_NAME='vnet-integrated-runner'                         # 任意の値としてください。「vnet」は仮想ネットワークの推奨される命名規則です
$SUBNET_NAME='snet-integrated-runner'                       # 任意の値としてください。「snet」はサブネットの推奨される命名規則です
$NSG_NAME='nsg-integrated-runner'                           # 任意の値としてください。「nsg」はネットワークセキュリティグループの推奨される命名規則です
$NETWORK_SETTINGS_RESOURCE_NAME='nsr-integrated-runner'     # 任意の値としてください。「nsr」はネットワークセキュリティルールの推奨される命名規則です
$DATABASE_ID='999999'                                           # 1.1で取得したデータベースID

# これらはデフォルト値です。アドレスとサブネットプレフィックスを任意の値へ調整してください。
$ADDRESS_PREFIX='10.100.0.0/16'
$SUBNET_PREFIX='10.100.1.0/24'

# 0. Azure CLI ログイン
az login --tenant $TENANT_ID
# 1. Register resource provider GitHub.Network
az provider register --namespace GitHub.Network
# 2. Create resource group $RESOURCE_GROUP_NAME at $AZURE_LOCATION
az group create --name $RESOURCE_GROUP_NAME --location $AZURE_LOCATION
# 3. Create NSG rules deployed with 'actions-nsg-deployment.bicep' file
az deployment group create --resource-group $RESOURCE_GROUP_NAME --template-file ./bicep/actions-nsg-deployment.bicep --parameters location=$AZURE_LOCATION nsgName=$NSG_NAME
# 4. Create vnet $VNET_NAME and subnet $SUBNET_NAME
az network vnet create --resource-group $RESOURCE_GROUP_NAME --name $VNET_NAME --address-prefix $ADDRESS_PREFIX --subnet-name $SUBNET_NAME --subnet-prefixes $SUBNET_PREFIX
# 5. Delegate subnet to GitHub.Network/networkSettings and apply NSG rules
az network vnet subnet update --resource-group $RESOURCE_GROUP_NAME --name $SUBNET_NAME --vnet-name $VNET_NAME --delegations GitHub.Network/networkSettings --network-security-group $NSG_NAME
# 6.Create network settings resource $NETWORK_SETTINGS_RESOURCE_NAME with 'networkSettings.bicep' file
az deployment group create --resource-group $RESOURCE_GROUP_NAME --template-file ./bicep/networkSettings.bicep --parameters location=$AZURE_LOCATION subscriptionId=$SUBSCRIPTION_ID resourceGroupName=$RESOURCE_GROUP_NAME vnetName=$VNET_NAME subnetName=$SUBNET_NAME networkSettingsName=$NETWORK_SETTINGS_RESOURCE_NAME databaseId=$DATABASE_ID
# 7. Get GitHubId from network settings resource
az resource show --resource-group $RESOURCE_GROUP_NAME --name $NETWORK_SETTINGS_RESOURCE_NAME --resource-type GitHub.Network/networkSettings --api-version 2024-04-02 --query "tags.GitHubId" --output tsv
