#!/usr/bin/env python3

import os
import shutil

packageManagers = {
     "arch": "pacman -Sy --noconfirm",
     "archarm": "pacman -Sy --noconfirm",
     "alpine": "apk update && apk add",
     "fedora": "dnf install -y",
     "termux": "pkg install -y",
     "ubuntu": "apt update && apt install -y",
     "debian": "apt update && apt install -y",
}

requirements = {
    "zsh": "bin",
    "bat": "bin",
    "exa": "bin",
    "git": "bin",
    "curl": "bin",
    "rsync": "bin",
    "reflector": "bin;+arch,+archarm",
    "btop": "bin;-fedora",
    "xclip": "bin;-archarm",
    "tldr": "bin;-alpine",
    "~/.oh-my-zsh": 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended',
}

dotFiles = {
    ".zshrc": ["~/.zshrc"],
    ".gitconfig": ["~/.gitconfig"],
}

def getDistro():
    """
    Get distro from /etc/os-release
    """
    with open("/etc/os-release") as f:
        for line in f:
            if line.startswith("ID"):
                return line.split("=")[1].strip()

def apply_patch(file):
    return os.popen("patch -p1 {0} {0}.patch --output - 2>/dev/null".format(file)).read()


def installPackages():
    # create list of packages to install
    bins = [key for key in requirements if requirements[key].startswith("bin") and "+" not in requirements[key] and "-"+distro not in requirements[key] and not shutil.which(key)]

    # create list of distro specific packages to install
    distro_specific = [key for key in requirements if "+"+distro in requirements[key] and not shutil.which(key)]

    # add distro specific packages to bins
    bins.extend(distro_specific)

    if len(bins) == 0:
        return

    # elevate privileges if necessary
    if os.geteuid() != 0:
        print("Elevating privileges...")
        os.system("sudo -E " + __file__)
        exit(0)

    # install packages
    print("Installing: " + " ".join(bins) + "...")

    if os.system(packageManagers[distro] + " " + " ".join(bins)) != 0:
        print("Failed to install packages, please install manually")
        exit(1)
    
    print("Installed: " + " ".join(bins))

def installPlugins():
    plugins = [key for key in requirements if not requirements[key].startswith("bin") and not os.path.exists(key.replace("~", os.environ["HOME"]))]

    if len(plugins) == 0:
        return
    
    # install plugins
    for plugin in plugins:
        print("Installing: " + plugin + "...")
        os.system(requirements[plugin])
        print("Installed: " + plugin)

def createPatch():
    # get changed files from git
    changed = os.popen("git --no-pager diff --name-only").read().split("\n")

    # filter out dot files
    changed = [file for file in changed if file in dotFiles]

    if len(changed) == 0:
        return
    
    # Ask if user wants to create a patch
    inp = input("Create patch? [y/N] ")
    if inp != "y" and inp != "Y":
        print("Please commit your changes")
        exit(1)

    # create patch file
    for file in changed:
        os.system("git diff -- {0} > {0}.patch".format(file))
        print("Created patch for " + file)
        # restore file
        os.system("git restore " + file)

def apply():
    notChanged = []
    changed = []

    # iterate over dot files
    for file, locations in dotFiles.items():
        for path in locations:
            path = path.replace("~", os.environ["HOME"])
            
            dotfile = ""

            # apply patch
            if os.path.exists(file + ".patch"):
                dotfile = apply_patch(file)
            else:
                # read dot file
                with open(file) as f:
                    dotfile = f.read()
            
            # compare dotfile with file from path
            with open(path) as f:
                file = f.read()
                if dotfile == file:
                    notChanged.append(path)
                    continue

            # write dot file
            with open(path, "w") as f:
                f.write(dotfile)
            
            changed.append(path)
    
    # print results

    print("======")
    if len(notChanged) > 0:
        print("Not changed:\n\t" + "\n\t".join(notChanged))
    if len(changed) > 0:
        print("Changed:\n\t" + "\n\t".join(changed))

# main

# set working directory to script location
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# get distro
distro = getDistro()

# install requirements
print("Installing requirements...")
installPackages()
installPlugins()
print("All requirements installed")

print("------")

# create patch files for changed dot files
print("Creating patch files for changed dot files...")
createPatch()

print("------")

# apply dot files
print("Applying dot files...")
apply()



