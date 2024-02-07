<#
.SYNOPSIS
Configures Azure DevOps for Azure AD Token Exchange

.DESCRIPTION
This script will create an Azure AD application and service principal, create role assignments, add federated credentials, and create Azure DevOps secrets for Azure AD Token Exchange.

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
    $AzDoOrganizationName,
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

# Get token from context for use when making REST call to run API
$token = (Get-AzAccessToken ).Token
$token = (Get-AzAccessToken -ResourceUrl "499b84ac-1321-427f-aa17-267ca6975798").Token


$URL = "https://dev.azure.com/$AzDoOrganizationName/$AzDoOProjectName/_apis/serviceendpoint/endpoints?api-version=6.0-preview.4"

(Invoke-RestMethod $URL -Headers $headers).Value

 # Create body for the API call
 $Body = @{
    data                             = @{
        subscriptionId   = $subscriptionId
        subscriptionName = $subscriptionName
        environment      = "AzureCloud"
        scopeLevel       = "Subscription"
        creationMode     = "Manual"
    }
    name                             = ($subscriptionName -replace " ")
    type                             = "AzureRM"
    url                              = "https://management.azure.com/"
    authorization                    = @{
        parameters = @{
            tenantid            = $tenantId
            serviceprincipalid  = $ServicePrincipalId
            authenticationType  = "spnKey"
            serviceprincipalkey = $PlainTextSecret
        }
        scheme     = "ServicePrincipal"
    }
    isShared                         = $false
    isReady                          = $true
    serviceEndpointProjectReferences = @(
        @{
            projectReference = @{
                id   = $AzDoProjectID
                name = $AzDoProjectName
            }
            name             = $AzDoConnectionName
        }
    )
}























GET https://dev.azure.com/{organization}/{project}/_apis/serviceendpoint/endpoints?api-version=6.0-preview.4



$header = @{
    'Authorization' = 'Bearer ' + $token
    'Content-Type' = 'application/json'
}

$headers = @{
    'Authorization' = 'Bearer ' + $token
}
    

# Create the header to authenticate to Azure DevOps
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $AzDoUserName, $AzDoToken)))
    $Header = @{
        Authorization = ("Basic {0}" -f $base64AuthInfo)
    }


 ## Get ProjectId
 $URL = "https://dev.azure.com/$AzDoOrganizationName/_apis/projects?api-version=6.0"

 $data = Invoke-RestMethod -Method 'GET' -Uri  $URL -Headers $headers
 $AzDoProjectNameproperties = 
   
    Try {
        $AzDoProjectNameproperties = (Invoke-RestMethod $URL -Headers $Header -ErrorAction Stop).Value
        Write-Verbose "Collected Azure DevOps Projects"
    }
    Catch {
        if ($_ | Select-String -Pattern "Access Denied: The Personal Access Token used has expired.") {
            Throw "Access Denied: The Azure DevOps Personal Access Token used has expired."
        }
        else {
            $ErrorMessage = $_ | ConvertFrom-Json
            Throw "Could not collect project: $($ErrorMessage.message)"
        }
    }
    $AzDoProjectID = ($AzDoProjectNameproperties | Where-Object { $_.Name -eq $AzDoProjectName }).id
    Write-Verbose "Collected ID: $AzDoProjectID"



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



















$subscriptionId = "{YOUR_SUBSCRIPTION_ID}"
$resourceGroupName = "{YOUR_RESOURCE_GROUP_NAME}"
$resourceGroupScope = "/subscriptions/$($subscriptionId)/resourcegroups/$($resourceGroupName)"
$identityName = "id-azuredevops"
$federatedCredentialName = "AzureDevOps"
$audience = "api://AzureADTokenExchange"
$issuerUrl = "{copy this value from the service connection draft in Azure DevOps}"
$subjectIdentifier = "{copy this value from the service connection draft in Azure DevOps}"


$identity = az identity create --name $identityName --resource-group $resourceGroupName | ConvertFrom-Json


$contributorRoleId = "b24988ac-6180-42a0-ab88-20f7382dd24c"
az role assignment create --assignee $identity.principalId --role $contributorRoleId --scope $resourceGroupScope


$userAccessAdministratorRoleId = "18d7d88d-d35e-4fb5-a5c3-7773c20a72d9"

# Allowed roles to be managed (e.g. assigned) by the pipeline identity to other managed identities e.g. other Azure resource
$allowedRoles = @(
    "4633458b-17de-408a-b874-0445c86b69e6",  # Key Vault Secrets User > Various Azure resources need to read secrets
    "ba92f5b4-2d11-453d-a403-e96b0029c9fe" # Storage Blob Data Contributor > Various Azure resources need to access blob storage
)

# Condition to make sure identity can only assign the allowed roles to other service principals
$userAccessAdministratorRoleCondition = ("
(
 (
  !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
 )
 OR 
 (
  @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {$($allowedRoles -join ", ")}
  AND
  @Request[Microsoft.Authorization/roleAssignments:PrincipalType] ForAnyOfAnyValues:StringEqualsIgnoreCase {'ServicePrincipal'}
 )
)
AND
(
 (
  !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
 )
 OR 
 (
  @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {$($allowedRoles -join ", ")}
  AND
  @Resource[Microsoft.Authorization/roleAssignments:PrincipalType] ForAnyOfAnyValues:StringEqualsIgnoreCase {'ServicePrincipal'}
 )
)
").replace("`n", "")
az role assignment create --assignee $identity.principalId --role $userAccessAdministratorRoleId --scope $resourceGroupScope --condition $userAccessAdministratorRoleCondition


$federatedCredentialName = "AzureDevOps"
$audience = "api://AzureADTokenExchange"
$issuerUrl = "{copy this value from the service connection draft in Azure DevOps}"
$subjectIdentifier = "{copy this value from the service connection draft in Azure DevOps}"
az identity federated-credential create --name $federatedCredentialName --identity-name $identityName --resource-group $resourceGroupName --issuer $issuerUrl --subject $subjectIdentifier --audiences $audience

$account = az account show | ConvertFrom-Json
$serviceConnection = New-Object -TypeName psobject
$serviceConnection | Add-Member NoteProperty -Name SubscriptionId -Value $account.id
$serviceConnection | Add-Member NoteProperty -Name SubscriptionName -Value $account.name
$serviceConnection | Add-Member NoteProperty -Name ServicePrincipalId -Value $identity.clientId
$serviceConnection | Add-Member NoteProperty -Name TenantId -Value $identity.tenantId
$serviceConnection | ConvertTo-Json