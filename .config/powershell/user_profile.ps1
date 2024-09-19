# Prompt
#
# i.e of theme from oh my posh webiste
# oh-my-posh init pwsh --config "$(scoop prefix oh-my-posh)\themes\paradox.omp.json" | Invoke-Expression
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

$omp_config = Join-Path $PSScriptRoot ".\takuya.omp.json"
oh-my-posh --init --shell pwsh --config $omp_config  | Invoke-Expression

Import-Module -Name Terminal-Icons

# PSReadLine
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle None
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineOption -PredictionSource History

# Fzf
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# Alias
Set-Alias vim nvim
Set-Alias g git
Set-Alias ll ls
Set-Alias grep findstr
Set-Alias tig 'E:\Program Files\Git\usr\bin\tig.exe'
Set-Alias less 'E:\Program Files\Git\usr\bin\less.exe'

# Utilities
function which ($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function gcmt([string]$message) {
	git commit -m $message
}


function dev() {
  cd "D:\SIGE\Documents\Control emisiones\Proyecto CEMSView\cemsview-frontend-dev"
}

function services() {
  cd "D:\SIGE\Documents\Control emisiones\Proyecto CEMSView\cemsview-services" 
}


<#
.SYNOPSIS
Obtiene y muestra información sobre las imágenes de los deployments en un clúster de Kubernetes.

.DESCRIPTION
La función `Get-ImageTags` permite obtener información detallada sobre las imágenes de los deployments en un clúster de Kubernetes. Puedes buscar por nombre de deployment, por namespace, o ambos.

.PARAMETER d
Nombre del deployment a buscar. Si se proporciona, se mostrará solo información sobre este deployment específico.

.PARAMETER n
Nombre del namespace en el que buscar los deployments. Si se proporciona, la búsqueda se limita a este namespace. Si no se proporciona, se buscará en todos los namespaces.

.EXAMPLE
Get-ImageTags
Muestra todos los deployments y sus tags en todos los namespaces.

.EXAMPLE
Get-ImageTags -n default
Muestra todos los deployments y sus tags en el namespace "default".

.EXAMPLE
Get-ImageTags -d my-deployment
Muestra información sobre el deployment "my-deployment" en todos los namespaces.

.EXAMPLE
Get-ImageTags -d my-deployment -n default
Muestra información sobre el deployment "my-deployment" en el namespace "default".

.OUTPUTS
Muestra una tabla con las columnas Deployment, Namespace, y Image.

.NOTES
Asegúrate de que `kubectl` esté instalado y configurado correctamente en tu entorno para usar esta función.
#>
function Get-ImageTags {
    param (
        [Alias("d")]                    # Alias para -d 
        [string]$Deployment = "",       # Nombre del deployment (opcional)

        [Alias("n")]                    # Alias para -n
        [string]$Namespace = ""         # Namespace (opcional)
    )

    # Condicional para usar el namespace si se ha proporcionado, o --all-namespaces por defecto
    if ($Namespace) {
        $namespaceOption = "--namespace=$Namespace"
    } else {
        $namespaceOption = "--all-namespaces"
    }

    # Si se ha proporcionado el deployment (-d o --deployment), filtrar por ese deployment
    if ($Deployment) {
        $jsonpath = '{range .items[?(@.metadata.name=="' + $Deployment + '")]}{.metadata.namespace}{"\t"}{.spec.template.spec.containers[*].image}{"\n"}{end}'
    } else {
        # Si no se proporciona -d, mostrar todos los deployments en el namespace o en todos los namespaces
        $jsonpath = '{range .items[*]}{.metadata.name}{"\t"}{.metadata.namespace}{"\t"}{.spec.template.spec.containers[*].image}{"\n"}{end}'
    }

    # Ejecutar el comando kubectl con la opción de namespace adecuada
    $deployments = kubectl get deployments $namespaceOption -o=jsonpath="$jsonpath"

     # Dividir la salida en filas y columnas dinámicamente
    $output = $deployments -split "`n" | ForEach-Object {
        if ($_ -ne "") {
            $columns = $_ -split "\t"
            $result = [PSCustomObject]@{}
            
            if ($DeploymentName -eq "") {
                if ($columns.Count -ge 2) {
                    $result | Add-Member -MemberType NoteProperty -Name "Deployment" -Value $columns[0]
                }
                if ($columns.Count -ge 3) {
                    $result | Add-Member -MemberType NoteProperty -Name "Namespace" -Value $columns[1]
                    $result | Add-Member -MemberType NoteProperty -Name "Image" -Value $columns[2]
                }
            } else {
                if ($columns.Count -ge 2) {
                    $result | Add-Member -MemberType NoteProperty -Name "Namespace" -Value $columns[0]
                    $result | Add-Member -MemberType NoteProperty -Name "Image" -Value $columns[1]
                }
            }
            
            $result
        }
    }

    # Mostrar la salida en formato tabla
    $output | Format-Table -AutoSize
}
