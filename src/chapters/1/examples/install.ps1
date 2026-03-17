iwr https://github.com/unremarkable-technology/tooling/releases/latest/download/intent-win32-x64.zip -OutFile intent.zip
Expand-Archive intent.zip -DestinationPath $env:USERPROFILE\bin -Force