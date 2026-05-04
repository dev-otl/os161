# Introduction
Scripts to setup os161 toolchain on linux system. 
Tested successfully on wsl2 and linux with **ubuntu version 22**.

# Install

    chmod +x ./install.sh && ./install.sh

This script runs all other scripts in sequence which perform the following operations:
+ Update system and install required build tools
+ Download source tarballs
+ Build the os161 toolchain and extract the os161 source tree
+ Configure the source tree, build userland, create disk images, and set up the working root directory
+ Test (build DUMBVM kernel and boot the system)
+ Permanently set the environment PATH

*If installation fails, try performing each step manually (explained later)*


# Output Directories
The **install location** is the parent directory of the current directory. After successful installation, all outputs can be found in `../os161`:

    ../os161/src        : OS161 source tree
    ../os161/root       : Configured working root (kernel, userland, disks, sys161.conf)
    ../os161/toolbuild  : Extracted tarballs (intermediate build artifacts)
    ../os161/tools      : Built toolchain
    ../os161/tools/bin  : Toolchain binaries — must be on PATH to use os161


### Note
After successful installation, a restart/relogin is needed to automatically add the os161 bin directory to the `PATH` variable.  
To immediately start using os161 in the current shell:

    export PATH=$PATH:../os161/tools/bin


# Install sequence example:    
|                                                                       |                                                              |
| --------------------------------------------------------------------- | ------------------------------------------------------------ |
| If you clone the repo by running command:                             | `git clone <REPO_URL> $HOME/os161Setup`                      |
| The path of the install script will be:                               | `$HOME/os161Setup/install.sh`                                |
| After successful installation,                                        | `cd $HOME/os161Setup; chmod +x ./install.sh && ./install.sh` |
| The os161 binaries will be found in:                                  | `$HOME/os161/tools/bin`                                      |
| The os161 source tree will be in:                                     | `$HOME/os161/src`                                            |
| The configured working root will be in:                               | `$HOME/os161/root`                                           |
| To start using os161 immediately, add bin directory to path manually: | `export PATH=$PATH:$HOME/os161/tools/bin`                    |
| Otherwise, restart or logout-login to autoset the PATH variable.      |                                                              |
| To check if path is set, run                                          | `command -v sys161`                                          |



# Manual install sequence (skip scripts as necessary)
The install script executes the following scripts in order.

## preSetupOS161.sh: Install required build tools

    chmod +x preSetupOS161.sh && ./preSetupOS161.sh

Runs `sudo apt-get install build-essential gdb libncurses-dev bmake` — **only for packages not already installed**. Does not run `apt upgrade`.

#### #skip by manually installing: build-essential gdb libncurses-dev bmake

    sudo apt install build-essential gdb libncurses-dev bmake


## downloadTarballs.sh: Download source tarballs
Downloads the following `.tar.gz` files. Skips files that are already present and valid:
+ binutils-2.24+os161-2.1.tar.gz
+ gcc-4.8.3+os161-2.1.tar.gz
+ gdb-7.8+os161-2.1.tar.gz
+ os161-base-2.0.3.tar.gz
+ sys161-2.0.8.tar.gz

#### #skip by manually downloading the tarballs (versions must match) into the downloads directory


## setupOS161.sh: Build toolchain and extract source (don't skip)
Extracts tarballs and builds binutils, gcc, gdb, and sys161. Also extracts the os161 source tree into `../os161/src`.

    chmod +x setupOS161.sh && ./setupOS161.sh

All outputs go under `../os161`.


## setupRoot.sh: Configure source tree and create working root directory
Configures `../os161/src` with the working root at `../os161/root`, builds and installs userland, creates disk images, and copies `sys161.conf`. Safe to re-run.

    chmod +x setupRoot.sh && ./setupRoot.sh

To reconfigure from scratch, remove `../os161/root` and re-run.

#### #skip if you want to configure the ostree yourself


## testBuild.sh: Build DUMBVM kernel and verify the installation
Builds the DUMBVM kernel inside `../os161/src` against the root created by `setupRoot.sh`, then boots it under `sys161`. A clean boot and shutdown confirms a working installation.

    chmod +x testBuild.sh && ./testBuild.sh

#### #skip if you don't want to build a kernel yet


## setEnvPermanent.sh: Persist the PATH variable
Adds `../os161/tools/bin` to `~/.bashrc` and `~/.bash_profile` / `~/.profile` so the toolchain is available in new shells automatically.

#### #skip by always setting PATH manually:
    export PATH=$PATH:path/to/os161/tools/bin


# VS Code Setup
A `.vscode/` folder is included in this repo with preconfigured tasks, launch, and IntelliSense settings. `setupRoot.sh` automatically copies it to `../os161/.vscode` during installation.

**Open VS Code at `../os161/`** — not the scripts repo. All paths in the config files are relative to that directory.

Included configs:

`tasks.json` — build tasks runnable from the Command Palette (`Terminal > Run Task`):

| Task | What it does |
|---|---|
| Copy Config | Copies `DUMBVM` to a new config name (prompts for name) |
| Run Config | Runs `./config <name>` to generate the compile directory |
| Make Depend | Runs `bmake depend` in the compile directory |
| Build and Install | Runs `bmake && bmake install` (default build task) |
| Run OS161 | Boots kernel under sys161 with GDB wait (`-w`) |
| Run OS161 (no debug) | Boots kernel under sys161 without debugger |

`launch.json` — GDB debug configuration. Start a debug session with F5 after running `Run OS161` (which waits for the debugger on `unix:.sockets/gdb`).

`c_cpp_properties.json` — IntelliSense include paths for the kernel source tree. The `root/include/` and `root/hostinclude/` entries are generated by `setupRoot.sh` and will not resolve until after installation.

`settings.json` — file associations for os161 header files.

# Links:
[OS161 Official website: (http://os161.org)](http://os161.org)

[Download tarballs here: (http://os161.org/download/)](http://os161.org/download/)

[!DON'T USE https link: (http**s**://os161.org)](http://os161.org)


# Building on linux with ubuntu 22
If you get a Python error, try removing the `python-is-python3` package:

    sudo apt remove python-is-python3


# Uninstall
    chmod +x uninstall.sh && ./uninstall.sh
Removes the `../os161` directory and the PATH entry added to your rc files.
