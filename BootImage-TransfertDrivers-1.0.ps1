######################################################################
#### Released: 6/29/2018                                          ####
#### Author: Loïc SEBAS                                           ####
#### Description : Copy drivers from one boot image to another    ####
######################################################################

### Loading Librairies
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName PresentationFramework

### Asking for SCCM Site Server FQDN
$SCCMSiteServer = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter your SCCM Site Server FQDN", "Site Server")

### Getting Site Code
try {
	$SCCMSiteCode = (([WMIClass]"\\$SCCMSiteServer\Root\SMS:SMS_ProviderLocation").GetInstances()).SiteCode
} Catch {
	[System.Windows.MessageBox]::Show('Error while retrieving info from SCCM Site Server. Please verify the FQDN you typed is correct', 'SCCM Site Server Connection error', 'Ok', 'Error')
	Exit 1
}


### Getting SCCM Site Code
$SCCMSiteCode = (([WMIClass]"\\$SCCMSiteServer\Root\SMS:SMS_ProviderLocation").GetInstances()).SiteCode
### Getting all Boot Images
$AllBootImagesOLD = ([WMIClass]"\\$SCCMSiteServer\Root\SMS\Site_GOV:SMS_BootImagePackage").GetInstances()
$AllBootImages = ([WMIClass]"\\$SCCMSiteServer\Root\SMS\Site_GOV:SMS_BootImagePackage").GetInstances()
### Selecting both Boot Images
$OriginalBootImage = $AllBootImagesOLD | Select-Object Name, PackageID, ImageOSVersion, ImagePath | Out-GridView -PassThru -Title "Select the Boot Image where you want to retrieve the drivers"
if (!($OriginalBootImage)) { Exit 1 }
$DestinationBootImage = $AllBootImages | Select Name, PackageID, ImageOSVersion, ImagePath | Out-GridView -PassThru -Title "Select the Boot Image where you want to inject the drivers"
if (!($DestinationBootImage)) { Exit 1 }

### Getting Drivers from the Original Boot Image
$SelectedOriginalBootImage = $AllBootImagesOLD | ? {$_.PackageID -eq $OriginalBootImage.PackageID}
$SelectedOriginalBootImage.Get()
### Injecting Drivers in the Destination Boot Image
$SelectedDestinationBootImage = $AllBootImages | ? {$_.PackageID -eq $DestinationBootImage.PackageID}
$SelectedDestinationBootImage.Get()

### Committing Changes
$SelectedDestinationBootImage.ReferencedDrivers += $SelectedOriginalBootImage.ReferencedDrivers
try {
	$SelectedDestinationBootImage.Put()
} Catch {
	[System.Windows.MessageBox]::Show('Error while adding drivers to the destination Boot Image. Please verify that you are not currently editing the destination Boot Image in the SCCM Console', 'Driver injection error', 'Ok', 'Error')
}
	