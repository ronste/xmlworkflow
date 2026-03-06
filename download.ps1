Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/sspworkflow/main/Dockerfile" -OutFile "Dockerfile"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/sspworkflow/main/Readme.md" -OutFile "Readme.md"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/sspworkflow/main/Documentation.md" -OutFile "Documentation.md"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/sspworkflow/main/sspworkflow-run-prod.sh" -OutFile "sspworkflow-run-prod.ps1"

