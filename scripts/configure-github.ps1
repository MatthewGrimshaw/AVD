<#
.SYNOPSIS
Configures GitHub for Azure AD Token Exchange

.DESCRIPTION
This script will create an Azure AD application and service principal, create role assignments, add federated credentials, and create GitHub secrets for Azure AD Token Exchange.

.EXAMPLE
configure-github.ps1 -tenantId "00000000-0000-0000-0000-000000000000" -subscriptionId "00000000-0000-0000-0000-000000000000" -appName "MyApp" -githubOrgName "MyOrg" -githubRepoName "MyRepo" -githubPat "0000000"

#>
param(
    [Parameter(Mandatory = $true)]
    [String]
    $tenantId,
    [Parameter(Mandatory = $true)]
    [String]
    $subscriptionId,
    [Parameter(Mandatory = $true)]
    [String]
    $appName,
    [String]
    $githubOrgName,
    [Parameter(Mandatory = $true)]
    [String]
    $githubRepoName,
    [Parameter(Mandatory = $true)]
    [String]
    $githubPat
)

# log in to Azure
Connect-AzAccount -Tenant $tenantId
Set-AzureSubscription -SubscriptionId  $subscriptionId


# Create an Azure Active Directory application and service principal
New-AzADApplication -DisplayName $appName
$clientId = (Get-AzADApplication -DisplayName $appName).AppId
New-AzADServicePrincipal -ApplicationId $clientId


# create role assignments
$objectId = (Get-AzADServicePrincipal -DisplayName $appName).Id
New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName Contributor

$clientId = (Get-AzADApplication -DisplayName $appName).Id

#Add federated credentials
New-AzADAppFederatedCredential -ApplicationObjectId $clientId -Audience api://AzureADTokenExchange -Issuer 'https://token.actions.githubusercontent.com' -Name "$($githubRepoName)-Production" -Subject "repo:$($githubOrgName)/$($githubRepoName):environment:Production"
New-AzADAppFederatedCredential -ApplicationObjectId $clientId -Audience api://AzureADTokenExchange -Issuer 'https://token.actions.githubusercontent.com' -Name "$($githubRepoName)-Canary" -Subject "repo:$($githubOrgName)/$($githubRepoName):environment:Canary"
New-AzADAppFederatedCredential -ApplicationObjectId $clientId -Audience api://AzureADTokenExchange -Issuer 'https://token.actions.githubusercontent.com' -Name "$($githubRepoName)-Test" -Subject "repo:$($githubOrgName)/$($githubRepoName):environment:Test"
New-AzADAppFederatedCredential -ApplicationObjectId $clientId -Audience api://AzureADTokenExchange -Issuer 'https://token.actions.githubusercontent.com' -Name "$($githubRepoName)-Dev" -Subject "repo:$($githubOrgName)/$($githubRepoName):environment:Dev"
New-AzADAppFederatedCredential -ApplicationObjectId $clientId -Audience api://AzureADTokenExchange -Issuer 'https://token.actions.githubusercontent.com' -Name "$($githubRepoName)-PR" -Subject "repo:$($githubOrgName)/$($githubRepoName):pull_request"
New-AzADAppFederatedCredential -ApplicationObjectId $clientId -Audience api://AzureADTokenExchange -Issuer 'https://token.actions.githubusercontent.com' -Name "$($githubRepoName)-Main" -Subject "repo:$($githubOrgName)/$($githubRepoName):ref:refs/heads/main"
New-AzADAppFederatedCredential -ApplicationObjectId $clientId -Audience api://AzureADTokenExchange -Issuer 'https://token.actions.githubusercontent.com' -Name "$($githubRepoName)-Branch" -Subject "repo:$($githubOrgName)/$($githubRepoName):ref:refs/heads/branch"

#install PSSodium if missing
If (!(Get-Module -ListAvailable -Name PSSodium)) {
    install-module PSSodium
}


#create GitHub Secrets
$clientAppId = (Get-AzADApplication -DisplayName $appName).AppId
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Subscription.TenantId

$headers = @{Authorization = "token " + $githubPat }

Invoke-RestMethod –Method get –Uri "https://api.github.com/repos/$($githubOrgName)/$($githubRepoName)/actions/secrets" –Headers $headers

$publicKey = (Invoke-RestMethod –Method get –Uri "https://api.github.com/repos/$($githubOrgName)/$($githubRepoName)/actions/secrets/public-key" –Headers $headers)

#AZURE_TENANT_ID
$encryptedSecret = ConvertTo-SodiumEncryptedString –Text $tenantId –PublicKey $($publicKey.key)
$Body = @"
{
    "encrypted_value": "$encryptedSecret",
    "key_id": "$($publicKey.key_id)"
}
"@

Invoke-RestMethod –Method Put –Uri "https://api.github.com/repos/$($githubOrgName)/$($githubRepoName)/actions/secrets/AZURE_TENANT_ID" –Headers $headers –body $Body

#AZURE_CLIENT_ID
$encryptedSecret = ConvertTo-SodiumEncryptedString –Text $clientAppId –PublicKey $($publicKey.key)
$Body = @"
{
    "encrypted_value": "$encryptedSecret",
    "key_id": "$($publicKey.key_id)"
}
"@

Invoke-RestMethod –Method Put –Uri "https://api.github.com/repos/$($githubOrgName)/$($githubRepoName)/actions/secrets/AZURE_CLIENT_ID" –Headers $headers –body $Body

#AZURE_SUBSCRIPTION_ID
$encryptedSecret = ConvertTo-SodiumEncryptedString –Text $subscriptionId  –PublicKey $($publicKey.key)
$Body = @"
{
    "encrypted_value": "$encryptedSecret",
    "key_id": "$($publicKey.key_id)"
}
"@

Invoke-RestMethod –Method Put –Uri "https://api.github.com/repos/$($githubOrgName)/$($githubRepoName)/actions/secrets/AZURE_SUBSCRIPTION_ID" –Headers $headers –body $Body