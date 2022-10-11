# azure-virtual-desktop-demo (avd)

Azure Virtual Desktop (AVD) Deployment example.

> Estimated resource creation-time: ~6m

```text
"The code speaks for itself."
```

## Summary

This demo creates an Azure Virtual Desktop deployment, containing a single Session Host.
A single "desktop" workspace is created.

Allowed users should be able to access the desktop at: https://client.wvd.microsoft.com/arm/webclient/index.html

Resources split into separate/optional sub-modules:

  * Azure Remote Desktop Session Hosts (Windows Virtual Machines)
  * Remote Desktop Apps
  * Azure Active Directory Users & Roles
  * Azure Remote Desktop AutoScaler


## AzureRM provider requirements

N/A


## AzureAD provider requirements

Terraform agent user is required to have the following rights (or equivalent) on the target tenant/subscription:
  
  * "Groups administrator" role in Azure for creating group(s).
  * "User administrator" role in Azure for creating user(s).
  * "Privileged role administrator" role in Azure for assigning Roles(s).
  * "Application administrator" role in Azure for assigning Roles(s).

> NOTE: "Microsoft.Authorization/roleAssignments/write" is disabled for "Contributor" role


## Reference documentation

  * Microsoft Learn: [AVD Joining AAD](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/wvd/azure-virtual-desktop-azure-active-directory-join)
  * Microsoft Learn: [AVD Deploy AAD-joined VMs](https://learn.microsoft.com/en-us/azure/virtual-desktop/deploy-azure-ad-joined-vm)
  * Microsoft Learn: [AVD Configure RBAC](https://learn.microsoft.com/en-us/azure/developer/terraform/configure-avd-rbac)
  * Microsoft Learn: [AVD AutoScaling](https://learn.microsoft.com/en-us/azure/virtual-desktop/autoscale-scenarios)
  * StackOverflow: [AAD-Fix](https://stackoverflow.com/questions/70743129/terraform-azure-vm-extension-does-not-join-vm-to-azure-active-directory-for-azur)
  * GitHub: [PauldoTyu](https://github.com/pauldotyu/azure-virtual-desktop-terraform)
  * Blog: [Schnerring](https://schnerring.net/blog/deploy-azure-virtual-desktop-avd-using-terraform-and-azure-active-directory-domain-services-aadds/)
  * Blog: [CloudNinja](https://www.cloudninja.nu/post/2022/07/github-terraform-azure-part6/)
  * Blog: [virtuallyflatfeet](https://virtuallyflatfeet.com/category/wvd/)

TODO: MSIX AppAttach Portal

> NOTE: AAD-join has limited [FSLOGIX](https://learn.microsoft.com/en-us/fslogix/overview) support.


## Desired State Configuration (DCS)

  * Microsoft Learn: [Desired State Configuration 2.0](https://learn.microsoft.com/en-us/powershell/dsc/overview?view=dsc-2.0)