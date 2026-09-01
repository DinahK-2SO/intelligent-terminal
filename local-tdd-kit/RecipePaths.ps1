function ConvertFrom-AppxRecipeSourcePath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $decoded = [Uri]::UnescapeDataString($Path)
    [IO.Path]::GetFullPath($decoded)
}
