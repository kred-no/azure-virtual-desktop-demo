# azure-virtual-desktop-demo (avd)

Azure Virtual Desktop (AVD) Deployment example.

## Executive Summary

```text
"The code speaks for itself."
```

This demo creates an Azure Virtual Desktop deployment, containing Session Host(s).
A single workspace is created, containing "RemoteDesktop" and "RemotApp" application groups.
Demo-account(s) for accessing the portal.

Authenticated AAD users should be able to access the desktop at: https://client.wvd.microsoft.com/arm/webclient/index.html

Resources split into separate/optional sub-modules:

  * Azure Remote Desktop Session Hosts (Windows Virtual Machines)
  * Remote Desktop Apps
  * Azure Active Directory Users & Roles
  * Azure Remote Desktop AutoScaler

A couple ove caveats:

  * Auto-Scaling [does NOT](https://learn.microsoft.com/en-us/azure/virtual-desktop/autoscale-faq) create/destroy VMs for you,
    only starts & stops them. While an Azure VM is in the “Stopped (Deallocated)” state, you will not be charged for the VM
    compute resources. However, you will still need to pay for any OS and data storage disks attached to the VM.
  * Deleting a VMs does not deregister them from the host-pool. If you re-create a VM with same name, it will not be able to
    join the host-pool (it has a different ID). Solution: generate a unique vm name/postfix each time.


## Deployment

> Estimated creation: ~15m

```text
AVD Resources: ~10s
AAD Resources: ~10s
VM Resources: ~6m
VM Extensions:
- AAD: ~2m
- HOSTPOOL: ~8m
- AADJPRIVATE: ~2m
```

## Connecting

```bash
# Optional: Get demo credentials
terraform output login
```

Go to [Azure Virtual Desktop portal](https://client.wvd.microsoft.com/arm/webclient/)
  1. Connect using HTML5-Client (no pre-requirements)
  2. Connect using RDP-file. Requires ["Windows Desktop Client"](https://learn.microsoft.com/en-us/azure/virtual-desktop/user-documentation/connect-windows-7-10)


## AzureRM provider requirements

N/A


## AzureAD provider requirements

Terraform operator is required to have the following rights (or equivalent) on the target tenant/subscription:
  
  * "Groups administrator" role in Azure for creating group(s).
  * "User administrator" role in Azure for creating user(s).
  * "Privileged role administrator" role in Azure for assigning Roles(s).
  * "Application administrator" role in Azure for assigning Roles(s).

> NOTE: "Microsoft.Authorization/roleAssignments/write" is disabled for "Contributor" role

The EASIEST solution is to make Terraform operator a subscription owner ..


## Reference documentation

  * Microsoft Learn: [Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)
  * Microsoft Learn: [AVD Joining AAD](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/wvd/azure-virtual-desktop-azure-active-directory-join)
  * Microsoft Learn: [AVD Deploy AAD-joined VMs](https://learn.microsoft.com/en-us/azure/virtual-desktop/deploy-azure-ad-joined-vm)
  * Microsoft Learn: [AVD Configure RBAC](https://learn.microsoft.com/en-us/azure/developer/terraform/configure-avd-rbac)
  * Microsoft Learn: [AVD AutoScaling](https://learn.microsoft.com/en-us/azure/virtual-desktop/autoscale-scenarios)
  * Microsoft Learn: [AVD Firewall](https://learn.microsoft.com/en-us/azure/firewall/protect-azure-virtual-desktop?tabs=azure)
  * Microsoft Learn: [AVD Sizing](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/virtual-machine-recs)
  * Microsoft Powershell: [Gallery](https://www.powershellgallery.com/)
  * StackOverflow: [AAD-Fix](https://stackoverflow.com/questions/70743129/terraform-azure-vm-extension-does-not-join-vm-to-azure-active-directory-for-azur)
  * Example: [PauldoTyu](https://github.com/pauldotyu/azure-virtual-desktop-terraform)
  * Blog: [Schnerring](https://schnerring.net/blog/deploy-azure-virtual-desktop-avd-using-terraform-and-azure-active-directory-domain-services-aadds/)
  * Blog: [CloudNinja-6](https://www.cloudninja.nu/post/2022/07/github-terraform-azure-part6/)
  * Blog: [CloudNinja-8](https://www.cloudninja.nu/post/2022/08/github-terraform-azure-part8/)
  * Blog: [virtuallyflatfeet](https://virtuallyflatfeet.com/category/wvd/)
  * Blog: [NathannEllans](https://www.nathannellans.com/post/deploying-azure-wvd-with-terraform)

> TODO: MSIX AppAttach Portal
> NOTE: AAD-join has limited [FSLOGIX](https://learn.microsoft.com/en-us/fslogix/overview) support. 


## Desired State Configuration (DCS)

  * Microsoft Learn: [Desired State Configuration 2.0](https://learn.microsoft.com/en-us/powershell/dsc/overview?view=dsc-2.0)


## Tips/Examples
  
  ```bash
  # Get list of VM images
  az vm image list-skus --publisher "MicrosoftWindowsDesktop" --offer "Windows-11" --location "norwayeast" --output table
  az vm image list-skus --publisher "MicrosoftWindowsDesktop" --offer "office-365" --location "norwayeast" --output table
    ```