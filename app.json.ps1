Describe 'app.json File Tests' {
    BeforeAll {
        $appJsonPath = Join-Path -Path $PSScriptRoot -ChildPath 'app.json'
        $appJsonContent = Get-Content -Path $appJsonPath -Raw | ConvertFrom-Json
    }

    Context 'File Existence and Structure' {
        It 'app.json file should exist' {
            Test-Path $appJsonPath | Should -Be $true
        }

        It 'app.json file should be valid JSON' {
            { $appJsonContent } | Should -Not -Throw
        }

        It '.gitignore file should exist' {
            $gitignorePath = Join-Path -Path $PSScriptRoot -ChildPath '.gitignore'
            Test-Path $gitignorePath | Should -BeTrue -Because '.gitignore file is required for proper version control'
        }
    }

    Context 'Publisher Information' {
        It 'should have "Winspire Solutions Pte. Ltd." as the publisher' {
            $appJsonContent.publisher | Should -Be 'Winspire Solutions Pte. Ltd.'
        }
    }

    Context 'Resource Exposure Policy' {
        It 'should have a resourceExposurePolicy object' {
            $appJsonContent.resourceExposurePolicy | Should -Not -BeNullOrEmpty
        }

        It 'should not allow downloading source' {
            $appJsonContent.resourceExposurePolicy.allowDownloadingSource | Should -Be $false
        }
    }

    Context 'Specific Value Check' {
        It 'allowDownloadingSource should be false' {
            $appJsonContent.resourceExposurePolicy.allowDownloadingSource | Should -BeFalse
        }
    }

    Context 'Forbidden Folders' {
        It 'should not contain .alpackages folder' {
            $alpackagesPath = Join-Path -Path $PSScriptRoot -ChildPath '.alpackages'
            Test-Path $alpackagesPath | Should -BeFalse -Because '.alpackages folder should not be present in the project'
        }

        It 'should not contain .snapshots folder' {
            $snapshotsPath = Join-Path -Path $PSScriptRoot -ChildPath '.snapshots'
            Test-Path $snapshotsPath | Should -BeFalse -Because '.snapshots folder should not be present in the project'
        }
    }
}
