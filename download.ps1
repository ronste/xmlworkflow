Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/xmlworkflow/main/Dockerfile" -OutFile "Dockerfile"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/xmlworkflow/main/Readme.md" -OutFile "Readme.md"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/xmlworkflow/main/Documentation.md" -OutFile "Documentation.md"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/xmlworkflow/main/xmlworkflow-run-prod.ps1" -OutFile "xmlworkflow-run-prod.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/xmlworkflow/main/runConversionChain.ps1" -OutFile "runConversionChain.ps1"


