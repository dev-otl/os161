# Introduction
Scripts to setup os161 toolchain on linux system. 
Tested successfully on wsl2 and linux with **ubuntu version 22**.

# Install

    chmod +x ./install.sh && ./install.sh

This script runs all other scripts in sequence which perform following operation in sequence:
+ update system
+ install necessary libraries to build os161
+ download files
+ install os161 
+ test (build DUMBVM kernel and boot the system)
+ permanently set environment path

*If installation fails, try performing each step manually (explained later)*


# Output Directories
The **install location** is the parent directory of the current directory. After succesful installation, all outputs can be found in `../os161` directory:

    ../os161/src        : OS161 base
    ../os161/toolbuild  : extracted tarballs
    ../os161/tools      : source files for binaries
    ../os161/tools/bin  : binaries used by sys161. *Must be placed in system to use os161*


### Note
After successfull installation, a restart/relogin is needed to auto add the os161 bin directory path to the environment `PATH` variable.    
To immediately start using os161 in the current shell, add `../os161/tools/bin` to path variable.


# Install sequence example:    
|                                                                       |                                                              |
| --------------------------------------------------------------------- | ------------------------------------------------------------ |
| If you clone the repo by running command:                             | `git clone <REPO_URL> $HOME/os161Setup`                      |
| The path of the install script will be:                               | `$HOME/os161Setup/install.sh`                                |
| After successful installation,                                        | `cd $HOME/os161Setup; chmod +x ./install.sh && ./install.sh` |
| The os161 binaries will be found in:                                  | `$HOME/os161/tools/bin`                                      |
| And the os161 base source files in:                                   | `$HOME/os161/src`                                            |
| To start using os161 immediately, add bin directory to path manually: | `export PATH=$PATH:$HOME/os161/tools/bin`                    |
| Otherwise, restart or logout-login to autoset the PATH variable.      |                                                              |
| To check if path is set, run                                          | `command -v sys161`                                          |



# Manual install  sequence (skip scripts as necessary)
The install script follows following sequence of script execution. So you can run/skip scripts as needed in your system.

## preSetupOS161.sh: Update system and install required build tools

    chmod +x preSetupOS161.sh && ./preSetupOS161.sh

which runs `sudo apt-get update && sudo apt-get install build-essential gdb libncurses-dev bmake` — **only for packages that are not already installed**. It does not run `apt upgrade` or modify any existing packages.

#### #skip script by manually installing: build-essential gdb libncurses-dev bmake 

    sudo apt install build-essential gdb libncurses-dev bmake



## downloadTarballs.sh: Download tarballs with necessary files to build os161
Downloads following .tar.gz files in current directory. Skips if already present:
+ binutils-2.24+os161-2.1.tar.gz
+ gcc-4.8.3+os161-2.1.tar.gz
+ gdb-7.8+os161-2.1.tar.gz
+ os161-base-2.0.3.tar.gz
+ sys161-2.0.8.tar.gz

#### #skip script by manually downloading the tarballs (versions must match) in current directory

## setupOS161.sh: Build OS161 Binaries (Actual installation. Don't skip)
This extracts the tarballs and builds the binaries.

    chmod +x setupOS161.sh && ./setupOS161.sh

Files are placed and built inside ../os161 directory.
## testBuild.sh: Tests working of os161
This build the DUMBVM kernel using sample config file and runs the system with this kernel. If everything installed correctly, the sys161 should boot and then shutdown.

#### #skip if you don't want to build a kernel yet

## setEnvPermanent.sh: sets environment path variable persistently
This places a script that runs at login and adds the os161/tools/bin directory to the PATH variable.

#### #skip by always manually setting PATH
    export PATH=$PATH:path/to/os161/tools/bin

# Links:
[OS161 Official website: (http://os161.org)](http://os161.org)

[Download tarballs here: (http://os161.org/download/)](http://os161.org/download/)

[!DON'T USE https link: (http**s**://os161.org)](http://os161.org)

# Building on linux with ubuntu 22
If you get python error, try removing python-is-python3 package

    sudo apt remove python-is-python3
    
# Uninstall
    chmod +x uninstall.sh && ./uninstall.sh
Removes os161 directory and script that sets PATH variable.
