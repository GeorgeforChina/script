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

VERSION
======
Bitshares version 0.1.12 and 0.1.13 are both supported, however, 0.1.13 is more recommended.

INSTALL
======
Use following command to install bitshares.
```Bash
pip3 install bitshares==0.1.13
```
If you have already installed bitshares python library, make sure that you have not make any change on it.
After bitshares is installed, download patch.sh script and patch on your bitshares lib.
If you run a virtual env, MAKE SURE YOU ARE IN VIRTUAL ENVIRONMENT. Your command prompt will show something 
like (venv) in front of normal prompt. Like
```Bash
(venv) user@hostname: dirname $
```

The script will check the installation path of your bitshares lib, which will be patched on, answer 'y' to confirm it.

```Bash
wget https://raw.githubusercontent.com/NebulaCybexDEX/script/master/cybex-py-lib/patch.sh
chmod u+x patch.sh
./patch.sh

```
