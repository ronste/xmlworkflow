param(
    [string]$ContainerImage = "sspworkflow:latest",
    [string]$Mode = "production",
    [switch]$Help
)

function Show-Help {
    Write-Host "Usage: .\sspworkflow-run-prod.ps1 [-ContainerImage <image>] [-Mode <mode>]"
    Write-Host "Default container image is 'sspworkflow:latest'."
    Write-Host "Mode can be 'production' (default), 'devtheme', or 'dev'."
}

if ($Help) {
    Show-Help
    exit 0
}

# Keep mode parameter for compatibility with the original script.
$null = $Mode

New-Item -ItemType Directory -Force -Path "work/metadata" | Out-Null
New-Item -ItemType Directory -Force -Path "store" | Out-Null

# Container names cannot include ':', so derive a stable runtime name from the image name.
$ContainerName = ($ContainerImage -split ":")[0]

$workPath = (Resolve-Path "work").Path
$storePath = (Resolve-Path "store").Path

# Don't bind themes folder, as they would not be available inside the container anymore.
if (Get-Command podman -ErrorAction SilentlyContinue) {
    podman container exists --external $ContainerName *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Container '$ContainerName' already exists. Starting it..."
        podman start $ContainerName | Out-Null
    }
    else {
        Write-Host "Container '$ContainerName' does not exist. Creating and starting it..."
        podman run -it --name $ContainerName -d `
            -v "${workPath}:/root/sspworkflow/work" `
            -v "${storePath}:/root/sspworkflow/store" `
            $ContainerImage | Out-Null
    }
}
elseif (Get-Command docker -ErrorAction SilentlyContinue) {
    docker container inspect $ContainerName *> $null
    if ($LASTEXITCODE -eq 0) {
        write-Host "Container '$ContainerName' already exists. Starting it..."
        docker start $ContainerName | Out-Null
    }
    else {
        write-Host "Container '$ContainerName' does not exist. Creating and starting it..."
        docker run -it --name $ContainerName -d `
            -v "${workPath}:/root/sspworkflow/work" `
            -v "${storePath}:/root/sspworkflow/store" `
            $ContainerImage | Out-Null
    }
}
else {
    Write-Error "Neither Podman nor Docker is installed. Please install one of them to run the container."
    exit 1
}
