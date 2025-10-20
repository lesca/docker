ARG TARGETARCH
FROM mcr.microsoft.com/azure-powershell:azurelinux-3.0 AS base_amd64
FROM mcr.microsoft.com/azure-powershell:azurelinux-3.0-arm64 AS base_arm64
FROM base_${TARGETARCH} AS base

# Install Azure CLI and other tools
RUN tdnf makecache \
 && tdnf install -y \
     azure-cli \
     git \
     net-tools \
     iputils \
     nmap-ncat \
     vim \
     wget \
     dnf \
     awk \
 && tdnf clean all

# Install .NET SDK and etc.
RUN dnf install -y dotnet-runtime-9.0 \
 && dnf clean all

# Install Bicep CLI
ARG TARGETARCH
RUN echo "TARGETARCH: $TARGETARCH" \
 && BICEP_URL="https://github.com/Azure/bicep/releases/latest/download/bicep-linux-$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x64")" \
 && echo "BICEP_URL: $BICEP_URL" \
 && curl -Lo bicep $BICEP_URL \
 && chmod +x ./bicep \
 && mv ./bicep /usr/local/bin/bicep

# Install PowerShell modules
RUN pwsh -Command " \
    Install-Module \
        -Name \
            Microsoft.Graph, \
            Microsoft.Entra, \
            PSWSMan, \
            ExchangeOnlineManagement, \
            MicrosoftTeams, \
            Microsoft.Online.SharePoint.PowerShell \
        -Scope AllUsers \
        -Repository PSGallery \
        -Force -AllowClobber; \
    Install-WSMan; \
    "

ENTRYPOINT [ "pwsh", "-c" ]