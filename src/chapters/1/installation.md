## Installation

The first step is to install the WA2 cli[^cli] `intent`. You’ll need an internet connection for the download. Since `intent` is a Rust binary it's a single file to install, or delete. 

> [!TIP]
> WA2 must be **trustworthy** to be useful, so it is open source.
> You should follow your security policies, and **trust but verify** before installing.
> You can view the source code for the book[^book], installation script[^script], and tooling[^tooling].

<!--
   TODO: if ever a PRINT version of book, need to comment on book text varying 
   from actual output as tooling evolves after printing.
 -->
The following steps install the latest release[^releases] of WA2 `intent`, and this
book assumes that version.

### Linux or macOS

> [!NOTE]
> We are assuming you place developer binaries in `~/.local/bin`.
> You can place the `intent` binary wherever you want, but ensure it's on your PATH.

If you're using Linux or macOS, open a terminal and run:
```console
curl -fsSL https://well.architected.to/install-intent.sh | sh
```

This script will:
* detect your platform and CPU architecture
* download the correct release from https://github.com/unremarkable-technology/tooling/releases
* install the intent binary to ~/.local/bin

After installation, verify:
```console
$ intent --help
```

If the command is not found, ensure ~/.local/bin is on your PATH.

### Windows

#### WSL 2

Install using the same command as Linux:
```console
curl -fsSL https://well.architected.to/install-intent.sh | sh
```

Verify:
```console
$ intent --help
```

If the command is not found, ensure ~/.local/bin is on your PATH.

#### PowerShell

> [!NOTE]
> We are assuming you place developer executables in `%USERPROFILE%\bin`.
> You can place the `intent.exe` wherever you want, but ensure it's on your PATH.

Download the latest release. The following command assumes you have PowerShell available:
```PowerShell
iwr https://github.com/unremarkable-technology/tooling/releases/latest/download/intent-win32-x64.zip -OutFile intent.zip
Expand-Archive intent.zip -DestinationPath $env:USERPROFILE\bin -Force
```
Then verify:

```PowerShell
intent --help
```

After installation you should be able to run intent from any terminal.


[^cli]: Command Line Interface

[^book]: https://github.com/unremarkable-technology/book

[^script]: https://well.architected.to/install-intent.sh

[^tooling]: https://github.com/unremarkable-technology/tooling

[^releases]: https://github.com/unremarkable-technology/tooling/releases/latest/
