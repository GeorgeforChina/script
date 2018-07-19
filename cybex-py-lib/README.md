INTRODUCTION
======
This is the readme file for installing, testing cybex python library.
Cybex src is a fork of bitshares. Cybex python library is also built on bitshares python library.

ENVIRONMENT
======
Python2.X is NOT supported.
We strongly recommend a virtual running enviroment to run your python program to visit cybex.
You may use the following command to create a virtualenv for python programs.

```Bash
virtualenv --no-site-package --python=`which python3` venv
cd venv
source ./bin/activate
```

More detail information for virtualenv can be found in virtualenv documentation
https://virtualenv.pypa.io/en/stable/

BITSHARES VERSION
======
Bitshares version 0.1.12 and 0.1.13 are both supported, however, 0.1.13 is STRONGLY recommended and FULLY tested.
For graphenelib, 0.6.1 is required. We have found several conflicts between bitshares version 0.1.13 and graphenelib version after 0.6.2

AUTO INSTALLATION
======
Currently, we build cybex python lib basing on bitshares python lib. You need first to install bitshares python library.
Use following command to install bitshares python lib.
```Bash
pip3 install graphenelib==0.6.1 bitshares==0.1.13
```
If you have already installed bitshares python library, make sure that you have not made any change on it.
After bitshares python lib is installed, download patch.sh script and run it. Patch.sh will automatically
extract patch files and patch on your bitshares lib.
If you are running in a virtual env, MAKE SURE YOU ARE IN VIRTUAL ENVIRONMENT. Your command prompt will be 
headed with (venv), where venv is the name of your virtual environment. Like:
```Bash
(venv) user@hostname: dirname $
```

The script will check the installation path of your bitshares lib, which will be patched on, answer 'y' to confirm it.
```Bash
wget https://raw.githubusercontent.com/NebulaCybexDEX/script/master/cybex-py-lib/patch.sh
chmod u+x patch.sh
./patch.sh
```

At the end of execution, you will get two commands, which can be used to rollback the patch when you need to recover
your bitshares python lib installation.

MANUALLY INSTALLATION
======
If you are not running auto patch script, you can also manually patch your bitshares library.
Files in document cybex_files can be copied to your bitshares installation path. Some files will be replaced and some to be added.
