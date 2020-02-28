#Prompt for some Prereq Information
$customer = read-host -prompt "Customer name"
$custabbrev = read-host -prompt "Customer Abbreviation"
$servicelevel = read-host -prompt "Service Level Purchased"
$enrolluseremail = read-host -prompt "Enrollment User (email address)"
$custcontact = read-host -prompt "Customer Primary Contact Name"
$custcontactemail = read-host -prompt "Customer Primary Contact Email"
$adminpw = read-host -prompt "CDW Internal Admin Password"

# Get .onmicrosoft.com domain name associated to tenant
$domain = Get-AzureadDomain | where-object { $_.isinitial -eq $TRUE }

# Get the TenantID associated to the initial directory
$tenantid = Get-AzureADTenantDetail 

# Create cdw internal admin user
$username = "cdw_internal_admin@" + $domain.name
$SecureStringPassword = ConvertTo-SecureString -String $adminpw -AsPlainText -Force
New-AzADUser -DisplayName "CDW Internal Admin" -UserPrincipalName $username -Password $SecureStringPassword -MailNickname "CDWInternalAdmin"

# Add new user to Global Admin role
$roleMember = Get-AzureADUser -ObjectId $username

# Fetch User Account Administrator role instance
$role = Get-AzureADDirectoryRole | Where-Object { $_.displayName -eq 'Company Administrator' }

# Add user to role
Add-AzureADDirectoryRoleMember -ObjectId $role.ObjectId -RefObjectId $roleMember.ObjectId

#Register app for Cloudhealth
$appName = "CDW-CloudHealth"
$appURI = "https://apps.cloudhealthtech.com"
$CHTApp = New-AzADApplication -DisplayName $appName -IdentifierUris $appURI

# Create Service Principal for CloudHealth App
$sp = New-AzADServicePrincipal -applicationid $chtapp.ApplicationId

# Create App Secret Key
$startDate = Get-Date
$enddate = "Sunday, December 31, 2299 6:00:00 AM"
$CHTsecret = New-AzureADApplicationPasswordCredential -ObjectId $CHTapp.objectid -CustomKeyIdentifier "CHT" -StartDate $startDate -enddate $enddate

#sleep 10 seconds to allow Service principal to be provisioned
Start-Sleep 10 

# Add reader role to CHT Service Principal
New-AzRoleAssignment -RoleDefinitionName reader -ServicePrincipalName $sp.ApplicationId

# Add Owner Role for CDW Internal Admin User
#New-AzRoleAssignment -RoleDefinitionName owner -ServicePrincipalName $roleMember.id

# Display Details
write-host -ForegroundColor yellow "Customer: " -NoNewline
write-host $customer " - " $custabbrev

write-host -ForegroundColor yellow "Service Level: " -NoNewline
write-host $servicelevel

write-host -ForegroundColor yellow "Customer Contact: " -NoNewline
write-host $custcontact " - " $custcontactemail

write-host -ForegroundColor yellow "Enrollment User: " -NoNewline
write-host $enrolluseremail

write-host -ForegroundColor yellow "ServicePrincipal: " -NoNewline
write-host $appname

write-host -ForegroundColor yellow "AppID: " -NoNewline
write-host $($CHTApp.applicationid)

write-host -ForegroundColor yellow "Initial Directory: " -NoNewline
write-host $domain.name

write-host -ForegroundColor yellow "TenantID: " -NoNewline
write-host $tenantid.objectid

write-host -ForegroundColor yellow "Client Secret Key: " -NoNewline
write-host $($CHTsecret.value)

write-host -ForegroundColor yellow "Client Secret Key Expiration: " -NoNewline
write-host $enddate

$cloudhealthsp = "CDW-" + $custabbrev + "-AZURE-SP"
write-host -ForegroundColor yellow "CloudHealth Service Principal Name: " -NoNewline
write-host $cloudhealthsp

$cloudhealthpoweruser = "CDW_" + $custabbrev + "_POWER_USER_ROLE"
write-host -ForegroundColor yellow "CloudHealth Power User Role: " -NoNewline
write-host $cloudhealthpoweruser

write-host ""

Write-Host -ForegroundColor yellow "Add the CDW Internal Admin credentials to the password vault"
write-host -ForegroundColor yellow "CDW Internal Admin UserID: " -NoNewline
write-host $username
write-host -ForegroundColor yellow "CDW Internal Admin Password: " -NoNewline
write-host $adminpw

write-host ""
write-host ""

# Generate Email with Enrollment Details:
write-host -ForegroundColor yellow "Copy/Paste the following into an email to the Azure TAM (brian.thiess@cdw.com)"
write-host $customer "has been enrolled as a Azure Services by CDW" $servicelevel "Customer." 
write-host "CloudHealth has been setup as of" $startDate 
write-host "Data should be available in CloudHealth by" $startdate.adddays(3)
write-host "Please schedule a walkthrough of the CloudHealth portal with the customer."
write-host "Enrollment User" $enrolluseremail

write-host "Use the following link to complete the rest of the setup in the CloudHealth portal"
write-host "https://wiki.services.cdw.com/w/Azure_-_Billing_%26_CloudHealth_Integration_for_Managed_Services_Customers"