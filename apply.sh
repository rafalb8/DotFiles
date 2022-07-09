#!/usr/bin/env python3

import os
import shutil
import re

_hdr_pat = re.compile("^@@ -(\d+),?(\d+)? \+(\d+),?(\d+)? @@$")

packageManagers = {
     "arch": "pacman -Sy",
     "archarm": "pacman -Sy",
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

def apply_patch(s,patch,revert=False):
    """
    Apply unified diff patch to string s to recover newer string.
    If revert is True, treat s as the newer string, recover older string.
    https://stackoverflow.com/a/40967337
    """
    s = s.splitlines(True)
    p = patch.splitlines(True)
    t = ''
    i = sl = 0
    (midx,sign) = (1,'+') if not revert else (3,'-')

    # skip header lines
    while i < len(p) and p[i].startswith(("---","+++","diff", "index")):
        i += 1 

    while i < len(p):
        m = _hdr_pat.match(p[i])
        if not m:
            raise Exception("Cannot process diff")
        i += 1
        l = int(m.group(midx))-1 + (m.group(midx+1) == '0')
        t += ''.join(s[sl:l])
        sl = l

        while i < len(p) and p[i][0] != '@':
            if i+1 < len(p) and p[i+1][0] == '\\':
                line = p[i][:-1]; i += 2
            else:
                line = p[i]; i += 1
            if len(line) > 0:
                if line[0] == sign or line[0] == ' ':
                    t += line[1:]
                sl += (line[0] != sign)
        t += ''.join(s[sl:])
    return t

def installPackages():
    # create list of packages to install
    bins = [key for key in requirements if requirements[key].startswith("bin") and "-"+distro not in requirements[key] and not shutil.which(key)]

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

            # read dot file
            with open(file) as f:
                dotfile = f.read()
            
            # apply patch
            if os.path.exists(file + ".patch"):
                dotfile = apply_patch(dotfile, open(file + ".patch").read())
            
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



