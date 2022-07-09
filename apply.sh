#!env python3

import os
import filecmp
import shutil

dotFileLocation = {
    ".zshrc": ["~/.zshrc"],
}

def apply(file, path):
    path = path.replace("~", os.environ["HOME"])
    if filecmp.cmp(file, path):
        print("Already applied: " + file)
        return

    # copy local file to path
    shutil.copy(file, path)
    print("Applied:\t" + file)


# main

# set working directory to script location
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# iterate over dot files
for fileName, locations in dotFileLocation.items():
    for location in locations:
        apply(fileName, location)


