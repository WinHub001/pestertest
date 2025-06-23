param (
    [string]$FilePath,
    [string]$OutputFile = "lint-result.xml"
)

# Validate
if (-not (Test-Path $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}

$lines = Get-Content -Path $FilePath
$issues = @()
$warning = @()
$lineNumber = 0

foreach ($line in $lines) {
    $lineNumber++

    if ($line -cmatch "ApplicationArea\s*=\s*(\w+)") {
        $appArea = [regex]::Match($line, "ApplicationArea\s*=\s*(\w+)").Groups[1].Value
        $allowed = @("All", "Basic", "Suite", "Advanced", "RelationshipMgmt", "SalesTax", "VAT", "BasicEU", "BasicNO", 
            "Dimensions", "SalesAnalysis", "InventoryAnalysis", "PurchaseAnalysis", "Location",
            "Assembly", "Manufacturing", "Planning", "Service", "ItemReferences",
            "RecordLinks", "Notes")
        if ($allowed -cnotcontains $appArea) {
            $issues += @{
                Line = $lineNumber
                Message = "Invalid ApplicationArea value: '$appArea' in '$FilePath'"
                Severity = "error"
            }
        }
    }
    if ($line -match "/\*\s*action\(") {
        $issues += @{ Line = $lineNumber; Message = "Commented-out action block detected in '$FilePath'"; Severity = "error" }
    }
    if ($line -notmatch "^\s*//") {
        if ($line -match "Error\s*\(\s*'[^']+'") {
            $issues += @{ Line = $lineNumber; Message = "Hardcoded Error message found (should use labels) in '$FilePath'"; Severity = "error" }
        }
        if ($line -match "Confirm\s*\(\s*'[^']+'") {
            $issues += @{ Line = $lineNumber; Message = "Hardcoded Confirm message found (should use labels) in '$FilePath'"; Severity = "error" }
        }
        if ($line -match "Message\s*\(\s*'[^']+'") {
            $issues += @{ Line = $lineNumber; Message = "Hardcoded Message text found (should use labels) in '$FilePath'"; Severity = "error" }
        }
    }
    if ($line -match "//\s*(field|action|procedure|part)\(") {
        $issues += @{ Line = $lineNumber; Message = "Commented-out AL object (field/action/procedure/part) in '$FilePath'"; Severity = "error" }
    }
    if ($line -match "begin\s*end;") {
        $warning += @{ Line = $lineNumber; Message = "Empty begin...end block"; Severity = "warning" }
    }
    if ($line -match "Visible\s*=\s*false;") {
        $warning += @{ Line = $lineNumber; Message = "UI element marked as Visible = false"; Severity = "warning" }
    }
    if ($line -match "TODO|ToDo|to-do") {
        $warning += @{ Line = $lineNumber; Message = "TODO found - consider resolving before production"; Severity = "warning" }
    }
    if ($line -match "\b(Codeunit|Page|Report|XmlPort)\.Run(Mod(al)?)?\s*\(\s*\d+") {
        $warning += @{ Line = $lineNumber; Message = "Hardcoded object ID used - consider symbolic names"; Severity = "warning" }
    }
    if ($line -match "DataClassification\s*=\s*ToBeClassified") {
        $warning += @{ Line = $lineNumber; Message = "DataClassification is 'ToBeClassified' - classify properly"; Severity = "warning" }
    }
}

# Generate JUnit XML
$xml = [System.Text.StringBuilder]::new()
$null = $xml.AppendLine("<testsuites>")
$null = $xml.AppendLine("  <testsuite name='AL Lint Results' tests='$($issues.Count)' failures='$($issues.Count)'>")

foreach ($issue in $issues) {
    $msg = [System.Security.SecurityElement]::Escape($issue.Message)
    $name = "Line $($issue.Line)"
    $null = $xml.AppendLine("    <testcase classname='ALLint' name='$name'>")
    $null = $xml.AppendLine("      <failure message='$msg' />")
    $null = $xml.AppendLine("    </testcase>")
}

$null = $xml.AppendLine("  </testsuite>")
$null = $xml.AppendLine("</testsuites>")
$xml.ToString() | Out-File -Encoding UTF8 -FilePath $OutputFile

# Display issues in console
foreach ($i in $issues) {
    $symbol = if ($i.Severity -eq 'error') { '❌' } else { '⚠️' }
    Write-Host "$symbol Line $($i.Line): $($i.Message)"
}

# Set exit code (non-zero if any errors)
if ($issues.Count -gt 0) {
    exit 1
} else {
    exit 0
}
