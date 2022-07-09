#!/usr/bin/env python3

import os
import filecmp
import shutil

packageManagers = {
     "arch": "pacman -Sy",
     "alpine": "apk update && apk add",
     "fedora": "dnf install -y",
     "termux": "pkg install -y",
     "ubuntu": "apt update && apt install -y",
     "debian": "apt update && apt install -y",
}

requirements = {
    "zsh": "bin",
    "bat": "bin",
    "git": "bin",
    "curl": "bin",
    "~/.oh-my-zsh": 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended',
}

dotFiles = {
    ".zshrc": ["~/.zshrc"],
}

def installPackages():
    # create list of packages to install
    bins = [key for key in requirements if requirements[key] == "bin" and not shutil.which(key)]

    if len(bins) == 0:
        return

    # elevate privileges if necessary
    if os.geteuid() != 0:
        print("Elevating privileges...")
        os.system("sudo -E " + __file__)
        exit(0)

    # install packages
    print("Installing: " + " ".join(bins))

    if os.system(packageManagers[distro] + " " + " ".join(bins)) != 0:
        print("Failed to install packages, please install manually")
        exit(1)
    
    print("Installed: " + " ".join(bins))

def installPlugins():
    plugins = [key for key in requirements if requirements[key] != "bin" and not os.path.exists(key.replace("~", os.environ["HOME"]))]


    if len(plugins) == 0:
        return
    
    # install plugins
    for plugin in plugins:
        print("Installing: " + plugin)
        os.system(requirements[plugin])
        print("Installed: " + plugin)
    


def apply():
    # set working directory to script location
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    # iterate over dot files
    for file, locations in dotFiles.items():
        for path in locations:
            path = path.replace("~", os.environ["HOME"])
            if filecmp.cmp(file, path):
                print("Already applied: " + file)
                continue

            # copy local file to path
            shutil.copy(file, path)
            print("Applied: " + file)


# main
# get distro from /etc/os-release
with open("/etc/os-release") as f:
    for line in f:
        if line.startswith("ID"):
            distro = line.split("=")[1].strip()
            break

# install requirements
installPackages()
installPlugins()

# apply dot files
apply()



