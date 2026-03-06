Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/xmlworkflow/main/Dockerfile" -OutFile "Dockerfile"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/xmlworkflow/main/Readme.md" -OutFile "Readme.md"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/xmlworkflow/main/Documentation.md" -OutFile "Documentation.md"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/xmlworkflow/main/xmlworkflow-run-prod.sh" -OutFile "xmlworkflow-run-prod.sh"
