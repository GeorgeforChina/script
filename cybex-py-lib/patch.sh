#!/bin/bash

PYTHON_CMD=python3
PIP_CMD=pip3
PYTHON_LIB_DIR=

PYTHON_VERSION=`$PYTHON_CMD --version | awk '{print $2}'`

if [[ ${PYTHON_VERSION:0:1} != "3" ]]; then
    echo "Error: Only python3 is supported"
    exit
fi

BITSHARES_VERSION=`$PIP_CMD show bitshares 2>/dev/null | grep -e "^Version" | awk -F': ' '{print $2}'`

if [ "$BITSHARES_VERSION" = "" ]; then
    echo "Error: Bitshares not installed in your python running environment"
    exit
else
    echo "Found bitshares version: $BITSHARES_VERSION"
fi

if [ "$BITSHARES_VERSION" = "0.1.12" ]; then
    BTSVER="12"
elif [ "$BITSHARES_VERSION" = "0.1.13" ]; then
    BTSVER="13"
else
    echo "Error: I can only patch on bitshares version 0.1.12~0.1.13, the installed version [$BITSHARES_VERSION] not supported"
    exit
fi
    
if [ "$PYTHON_LIB_DIR" = "" ]; then
    PYTHON_LIB_DIR=`$PYTHON_CMD -c "from distutils.sysconfig import get_python_lib; print(get_python_lib());"`
fi

# eliminate the tailing '/'
PYTHON_LIB_DIR=`dirname $PYTHON_LIB_DIR`/`basename $PYTHON_LIB_DIR`

BITSHARES_DIR=$PYTHON_LIB_DIR/bitshares
BITSHARESBASE_DIR=$PYTHON_LIB_DIR/bitsharesbase

if [ ! -d $BITSHARES_DIR ]; then
    echo "Error: Cannot find bitshares directory under $PYTHON_LIB_DIR, please manually set PYTHON_LIB_DIR in this script"
    exit
fi

if [ ! -d $BITSHARESBASE_DIR ]; then
    echo "Error: Cannot find bitsharesbase directory under $PYTHON_LIB_DIR, please manually set PYTHON_LIB_DIR in this script"
    exit
fi

echo -n "Patch bitshares installed in directory $PYTHON_LIB_DIR? (y/N) "
read answer
if [ "$answer" != "y" ]; then
    echo "Error: please answer y to patch"
    exit 0
fi

echo "Backup old directory"
#backup old directories
TIMESTAMP=`date +"%Y%m%d_%H_%M_%S"`

BITSHARES_PATCH_FILE=/tmp/bitshares_patch_${BTSVER}_${TIMESTAMP}.patch
BITSHARESBASE_PATCH_FILE=/tmp/bitsharesbase_patch_${BTSVER}_${TIMESTAMP}.patch

pushd $PYTHON_LIB_DIR 1>/dev/null
tar -cf /tmp/bitshares_${TIMESTAMP}.tar bitshares
tar -cf /tmp/bitsharesbase_${TIMESTAMP}.tar bitsharesbase
popd 1>/dev/null

if [ "$BTSVER" = "12" ]; then
cat >$BITSHARES_PATCH_FILE <<EOF
diff -Nur -x __pycache__ -x 'cybex*' bitshares_old/bitshares.py bitshares/bitshares.py
--- bitshares_old/bitshares.py  2018-04-04 15:34:42.952270269 +0800
+++ bitshares/bitshares.py      2018-04-20 11:33:16.782725243 +0800
@@ -5,6 +5,7 @@
 from bitsharesapi.bitsharesnoderpc import BitSharesNodeRPC
 from bitsharesbase.account import PrivateKey, PublicKey
 from bitsharesbase import transactions, operations
+from graphenebase.types import Set
 from .asset import Asset
 from .account import Account
 from .amount import Amount
@@ -441,6 +442,11 @@
             bitshares_instance=self
         )
 
+        if 'extensions' in kwargs and kwargs['extensions']:
+            extensions=kwargs['extensions']
+        else:
+            extensions=Set([])
+
         op = operations.Transfer(**{
             "fee": {"amount": 0, "asset_id": "1.3.0"},
             "from": account["id"],
@@ -450,6 +456,7 @@
                 "asset_id": amount.asset["id"]
             },
             "memo": memoObj.encrypt(memo),
+            "extensions": extensions,
             "prefix": self.prefix
         })
         return self.finalizeOp(op, account, "active", **kwargs)
EOF
cat >$BITSHARESBASE_PATCH_FILE <<EOF
diff -Nur -x __pycache__ -x 'cybex*' bitsharesbase_old/operationids.py bitsharesbase/operationids.py
--- bitsharesbase_old/operationids.py   2018-04-04 15:34:42.956270217 +0800
+++ bitsharesbase/operationids.py       2018-04-20 11:35:10.448713470 +0800
@@ -47,6 +47,7 @@
     "fba_distribute",
     "bid_collateral",
     "execute_bid",
+    "cancel_vesting"
 ]
 operations = {o: ops.index(o) for o in ops}
 
diff -Nur -x __pycache__ -x 'cybex*' bitsharesbase_old/operations.py bitsharesbase/operations.py
--- bitsharesbase_old/operations.py     2018-04-04 15:34:42.956270217 +0800
+++ bitsharesbase/operations.py 2018-04-20 11:34:53.712420721 +0800
@@ -1,5 +1,6 @@
 from collections import OrderedDict
 import json
+from bitshares.cybexobjects import CybexExtension
 from graphenebase.types import (
     Uint8, Int16, Uint16, Uint32, Uint64,
     Varint32, Int64, String, Bytes, Void,
@@ -55,13 +56,19 @@
                     memo = Optional(Memo(kwargs["memo"]))
             else:
                 memo = Optional(None)
+
+            if 'extensions' in kwargs and  isinstance(kwargs['extensions'],list) and len(kwargs['extensions'])>0:
+                extensions=CybexExtension(kwargs['extensions'])
+            else:
+               extensions=Set([])
+
             super().__init__(OrderedDict([
                 ('fee', Asset(kwargs["fee"])),
                 ('from', ObjectId(kwargs["from"], "account")),
                 ('to', ObjectId(kwargs["to"], "account")),
                 ('amount', Asset(kwargs["amount"])),
                 ('memo', memo),
-                ('extensions', Set([])),
+                ('extensions', extensions),
             ]))
 
 
@@ -562,3 +569,17 @@
                 ('committee_member_account', ObjectId(kwargs["committee_member_account"], "account")),
                 ('url', String(kwargs["url"])),
             ]))
+
+
+class Cancel_vesting(GrapheneObject):
+    def __init__(self, *args, **kwargs):
+        if isArgsThisClass(self, args):
+                self.data = args[0].data
+        else:
+            if len(args) == 1 and len(kwargs) == 0:
+                kwargs = args[0]
+            super().__init__(OrderedDict([
+                ('fee', Asset(kwargs["fee"])),
+                ('sender', ObjectId(kwargs["sender"],"account")),
+                ('balance_object', ObjectId(kwargs["balance_object"])),
+            ]))
EOF

elif [ "$BTSVER" = "13" ]; then  # if [ "$BTSVER" = "12" ]; then...
cat >$BITSHARES_PATCH_FILE <<EOF
diff -Nur -x __pycache__ -x 'cybex*' bitshares_old/bitshares.py bitshares/bitshares.py
--- bitshares_old/bitshares.py  2018-04-04 14:24:06.978826045 +0800
+++ bitshares/bitshares.py      2018-04-20 10:47:28.602662623 +0800
@@ -5,6 +5,7 @@
 from bitsharesapi.bitsharesnoderpc import BitSharesNodeRPC
 from bitsharesbase.account import PrivateKey, PublicKey
 from bitsharesbase import transactions, operations
+from graphenebase.types import Set
 from .asset import Asset
 from .account import Account
 from .amount import Amount
@@ -473,6 +474,11 @@
             bitshares_instance=self
         )
 
+        if 'extensions' in kwargs and kwargs['extensions']:
+            extensions=kwargs['extensions']
+        else:
+            extensions=Set([])
+
         op = operations.Transfer(**{
             "fee": {"amount": 0, "asset_id": "1.3.0"},
             "from": account["id"],
@@ -482,6 +488,7 @@
                 "asset_id": amount.asset["id"]
             },
             "memo": memoObj.encrypt(memo),
+            "extensions": extensions,
             "prefix": self.prefix
         })
         return self.finalizeOp(op, account, "active", **kwargs)
EOF
cat >$BITSHARESBASE_PATCH_FILE <<EOF
diff -Nur -x __pycache__ -x 'cybex*' bitsharesbase_old/operationids.py bitsharesbase/operationids.py
--- bitsharesbase_old/operationids.py   2018-04-04 14:24:06.982826232 +0800
+++ bitsharesbase/operationids.py       2018-04-20 10:51:06.182475472 +0800
@@ -47,6 +47,7 @@
     "fba_distribute",
     "bid_collateral",
     "execute_bid",
+    "cancel_vesting"
 ]
 operations = {o: ops.index(o) for o in ops}
 
diff -Nur -x __pycache__ -x 'cybex*' bitsharesbase_old/operations.py bitsharesbase/operations.py
--- bitsharesbase_old/operations.py     2018-04-04 14:24:06.982826232 +0800
+++ bitsharesbase/operations.py 2018-04-20 10:50:43.374075796 +0800
@@ -1,5 +1,6 @@
 from collections import OrderedDict
 import json
+from bitshares.cybexobjects import CybexExtension
 from graphenebase.types import (
     Uint8, Int16, Uint16, Uint32, Uint64,
     Varint32, Int64, String, Bytes, Void,
@@ -55,13 +56,19 @@
                     memo = Optional(Memo(kwargs["memo"]))
             else:
                 memo = Optional(None)
+
+            if 'extensions' in kwargs and  isinstance(kwargs['extensions'],list) and len(kwargs['extensions'])>0:
+                extensions=CybexExtension(kwargs['extensions'])
+            else:
+               extensions=Set([])
+
             super().__init__(OrderedDict([
                 ('fee', Asset(kwargs["fee"])),
                 ('from', ObjectId(kwargs["from"], "account")),
                 ('to', ObjectId(kwargs["to"], "account")),
                 ('amount', Asset(kwargs["amount"])),
                 ('memo', memo),
-                ('extensions', Set([])),
+                ('extensions', extensions),
             ]))
 
 
@@ -562,3 +569,17 @@
                 ('committee_member_account', ObjectId(kwargs["committee_member_account"], "account")),
                 ('url', String(kwargs["url"])),
             ]))
+
+
+class Cancel_vesting(GrapheneObject):
+    def __init__(self, *args, **kwargs):
+        if isArgsThisClass(self, args):
+                self.data = args[0].data
+        else:
+            if len(args) == 1 and len(kwargs) == 0:
+                kwargs = args[0]
+            super().__init__(OrderedDict([
+                ('fee', Asset(kwargs["fee"])),
+                ('sender', ObjectId(kwargs["sender"],"account")),
+                ('balance_object', ObjectId(kwargs["balance_object"])),
+            ]))
EOF
fi # end if [ "$BTSVER" = "12"]

pushd $BITSHARES_DIR
patch -p1 <$BITSHARES_PATCH_FILE
popd

pushd $BITSHARESBASE_DIR
patch -p1 <$BITSHARESBASE_PATCH_FILE
popd

echo "Patch successed"
echo "If you want to revert to old bitshares version, using command"
echo "cd $BITSHARES_DIR; patch -Rp1 <$BITSHARES_PATCH_FILE"
echo "cd $BITSHARESBASE_DIR; patch -Rp1 <$BITSHARESBASE_PATCH_FILE"
