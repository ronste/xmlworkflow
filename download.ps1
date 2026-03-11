Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/sspworkflow/main/Dockerfile" -OutFile "Dockerfile"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/sspworkflow/main/Readme.md" -OutFile "Readme.md"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/sspworkflow/main/Documentation.md" -OutFile "Documentation.md"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/sspworkflow/main/sspworkflow-run-prod.ps1" -OutFile "sspworkflow-run-prod.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/sspworkflow/main/runConversionChain.ps1" -OutFile "runConversionChain.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/sspworkflow/main/setup-completion.ps1" -OutFile "setup-completion.ps1"

