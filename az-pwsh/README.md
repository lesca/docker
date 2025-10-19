This is an all-in-one docker image includes Azure PowerShell, Graph Powershell SDK, Azure CLI, Bicep CLI, .Net runtime, etc. The image is updated weekly to keep everything up-to-date.

The docker images are published in [Docker Hub](https://hub.docker.com/r/lesca/az-pwsh).

## How to use the image?

You can simply pull the image by:

```bash
docker pull lesca/az-pwsh:latest
```

and run the image by:

```bash
docker run --rm -it lesca/az-pwsh:latest pwsh
```

Or, you can run the image in detach mode:

```bash
docker run -d --name azure lesca/az-pwsh:latest sleep infinity
docker exec -it azure pwsh
```

Also, you can mount a folder in detached mode:

```bash
docker run -d \
  --mount type=bind,source="$(pwd)/scripts",target=/root/scripts \
  --name azure lesca/az-pwsh:latest \
  sleep infinity
docker exec -it azure pwsh
```

### Using with VS Code Dev Container

You can then connect to the running container from **VS code** -> `Dev Containers: Attach to Running Container...`

You can also simplify the process by adding a `.devcontianer.json` file in your project folder:

```json
{
  "name": "az-pwsh",
  "image": "lesca/az-pwsh:dev",
  "workspaceFolder": "/root/azure",
  "workspaceMount": "source=${localWorkspaceFolder},target=/root/azure,type=bind,consistency=cached",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.powershell",
        "ms-vscode.azurecli",
        "ms-azuretools.vscode-bicep"
      ],
      "settings": {
        "http.proxy": "http://host.docker.internal:8080",
        "http.proxyStrictSSL": false
      }
    }
  }
}
```

Then, you can open the folder with `Dev Containers: Open Folder in Container...` command.

## Why do I need this?

The image is based on [Azure Powershell](https://learn.microsoft.com/en-us/powershell/azure).

For windows, you can also use [MSI package](https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows?pivots=windows-msi) to install everything, however you need to manually maintain other moudles. Let's say the [Graph](https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation) moudles, the update is very time-wasting.

## What does the image have?

### Azure PowerShell

The workflow always uses official images from Microsoft. No 3rd party images are used. 

You can find the images from the registry below:

- [Microsoft Artifact Registry](https://mcr.microsoft.com/en-us/catalog)

The base image:

- [Azure PowerShell (Docker Hub)](https://hub.docker.com/r/microsoft/azure-powershell)
- [Azure PowerShell (MCR)](https://mcr.microsoft.com/en-us/artifact/mar/azure-powershell/tags)

The tags used:

- azurelinux-3.0 - for AMD64 CPU
- azurelinux-3.0-arm64 - for ARM64 CPU

### Azure CLI

This is installed by the `tdnf` the package mananger of **AzureLinux 3.0** distribution. 

You can also install it from Github - [https://github.com/Azure/azure-cli/releases](https://github.com/Azure/azure-cli/releases)

### Bicep CLI

This is installed by an [installation script](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#install-manually) from Microsoft.

The installation source is from Github releases: [https://github.com/Azure/bicep/releases](https://github.com/Azure/bicep/releases)

Resources:

- [ARM API](https://learn.microsoft.com/en-us/azure/templates/)

### PS Modules

The workflow always uses official PowerShell modules from Microsoft. No 3rd party modules are used. 

To get a full list of installed modules, you can list the available modules by `Get-InstalledModule` and `Get-Module -ListAvailable`

#### Installed Modules

- [Azure PowerShell](https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell)
  - [MCR image](https://mcr.microsoft.com/en-us/artifact/mar/azure-powershell/tags)
  - [Connect](https://learn.microsoft.com/en-us/powershell/azure/get-started-azureps)
  - [Cmdlet Reference](https://learn.microsoft.com/en-us/powershell/module/az.accounts)
  - [Migration from AzureAD](https://learn.microsoft.com/en-us/powershell/azure/azps-msgraph-migration-changes)
- [Microsoft.Graph](https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation)
  - [MCR image](https://mcr.microsoft.com/en-us/artifact/mar/microsoftgraph/powershell)
  - [Overview](https://learn.microsoft.com/en-us/graph/overview)
  - [Connect](https://learn.microsoft.com/en-us/powershell/microsoftgraph/authentication-commands)
  - [API Reference](https://learn.microsoft.com/en-us/graph/api/overview)
  - [Permission Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
  - [Query](https://learn.microsoft.com/en-us/graph/query-parameters)
  - [Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer)
  - [AzureAD cmdlet map](https://learn.microsoft.com/en-us/powershell/microsoftgraph/azuread-msoline-cmdlet-map)
- [Microsoft.Entra](https://learn.microsoft.com/en-us/powershell/entra-powershell/installation)
  - [Connect](https://learn.microsoft.com/en-us/powershell/entra-powershell/navigate-entraps)
  - [Cmdlet Reference](https://learn.microsoft.com/en-us/powershell/module/microsoft.entra)
  - [AzureAD cmdlet map](https://learn.microsoft.com/en-us/powershell/entra-powershell/azuread-powershell-to-entra-powershell-mapping)
- [PSWSMan](https://www.powershellgallery.com/packages/PSWSMan) 
  - It's [required](https://learn.microsoft.com/en-us/powershell/exchange/exchange-online-powershell-v2?view=exchange-ps#apple-macos) by ExchangeOnlineManagement module below.
- [ExchangeOnlineManagement](https://learn.microsoft.com/en-us/powershell/exchange/exchange-online-powershell)
  - [Connect](https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-online-powershell)
  - [Cmdlet Reference](https://learn.microsoft.com/en-us/powershell/module/exchangepowershell)
- [MicrosoftTeams](https://learn.microsoft.com/en-us/microsoftteams/teams-powershell-install)
  - [Connect](https://learn.microsoft.com/en-us/microsoftteams/teams-powershell-managing-teams)
  - [Cmdlet Reference](https://learn.microsoft.com/en-us/powershell/module/microsoftteams)
- [Microsoft.Online.SharePoint.PowerShell](https://learn.microsoft.com/en-us/powershell/sharepoint/sharepoint-online/connect-sharepoint-online)
  - [Connect](https://learn.microsoft.com/en-us/powershell/sharepoint/sharepoint-online/connect-sharepoint-online#to-connect-with-a-user-name-and-password)
  - [Cmdlet Reference](https://learn.microsoft.com/en-us/powershell/module/microsoft.online.sharepoint.powershell)

#### Deprecated Modules:

- [AzureAD](https://www.powershellgallery.com/packages/AzureAD) and [MSOnline](https://www.powershellgallery.com/packages/msonline) 
  - it's [deprecated](https://techcommunity.microsoft.com/blog/microsoft-entra-blog/action-required-msonline-and-azuread-powershell-retirement---2025-info-and-resou/4364991) and not suitable for PowerShell Core edition. Thus they are not installed within the image.
  - [Migration FAQ](https://learn.microsoft.com/en-us/powershell/azure/active-directory/migration-faq)

## How to load PFX certs

You can use below script to load PFX certs in to `My` cert store:

```pwsh
function Import-PfxToCertStore {
    param (
        [string]$pfx,
        [string]$pass
    )
    # import the PFX to your machines cert store
    $StoreName = [System.Security.Cryptography.X509Certificates.StoreName]::My 
    $StoreLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser 
    $Store = [System.Security.Cryptography.X509Certificates.X509Store]::new($StoreName, $StoreLocation) 
    $Flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
    $Certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($pfx, $pass, $Flag) 
    $Store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite) 
    $Store.Add($Certificate) 
    $Store.Close()
}
```
For AzCLI you need to convert pfx to pem before you can connect:

```pwsh
openssl pkcs12 -in $pfxPath --out $pemPath --nodes
az login --service-principal -u $clientId --certificate $pemPath --tenant $tenantId
```

Note: pem is not encrypted. Permenantly delete it after you finish your work.

## How to upgrade PowerShell

In some cases, you may want to install a newer version of PowerShell. Since we are using **AzureLinux 3.0**, it's using `rpm` packages, we can refer to the installation guide from [RHEL](https://learn.microsoft.com/en-us/powershell/scripting/install/install-rhel?view=powershell-7.5#installation-via-direct-download).


First, you can visit the [Azure PowerShell release page](https://github.com/PowerShell/PowerShell/releases/latest) and find the package link.

Then, use `dnf install -y` following the link, e.g:

```bash
dnf install -y https://github.com/PowerShell/PowerShell/releases/download/v7.5.3/powershell-7.5.3-1.cm.aarch64.rpm
```
