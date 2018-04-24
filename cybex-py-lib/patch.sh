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
diff -Nur -x __pycache__ bitshares_old/bitshares.py bitshares/bitshares.py
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
diff -Nur -x __pycache__ bitshares_old/cybexlib.py bitshares/cybexlib.py
--- bitshares_old/cybexlib.py   1970-01-01 08:00:00.000000000 +0800
+++ bitshares/cybexlib.py       2018-04-20 14:30:14.304833632 +0800
@@ -0,0 +1,162 @@
+from bitshares import BitShares
+from bitsharesapi.bitsharesnoderpc import BitSharesNodeRPC
+from bitsharesbase.account import PrivateKey, PublicKey
+from bitsharesbase import transactions, operations
+from bitshares.asset import Asset
+from bitshares.account import Account
+from binascii import hexlify, unhexlify
+from graphenebase.base58 import base58decode,base58encode,doublesha256,ripemd160, Base58
+import hashlib
+
+import logging
+import os
+import getpass
+
+log = logging.getLogger(__name__)
+
+def unlock(inst, *args, **kwargs):
+    if inst.wallet.created():
+        if "UNLOCK" in os.environ:
+            pwd = os.environ["UNLOCK"]
+        else:
+            pwd = getpass.getpass("Current Wallet Passphrase:")
+        inst.wallet.unlock(pwd)
+    else:
+        print("No wallet installed yet. Creating ...")
+        pwd = getpass.getpass("Wallet Encryption Passphrase:")
+        inst.wallet.create(pwd)
+
+
+
+def fill_order_history( bitshares, base, quote, limit=100,):
+        """ Returns a generator for individual account transactions. The
+            latest operation will be first. This call can be used in a
+            ``for`` loop.
+
+            :param asset base:  
+            :param asset quote:  
+            :param int limit: limit number of items to
+                return (*optional*)
+        """
+        
+        asset_a=Asset(base)
+        asset_b=Asset(quote)
+
+        return bitshares.rpc.get_fill_order_history(
+            asset_a["id"],
+            asset_b["id"],
+            limit,
+            api="history"
+        )
+
+
+
+
+def market_history( bitshares, base,quote,bucket_seconds,start,end):
+        """ Returns a generator for individual account transactions. The
+            latest operation will be first. This call can be used in a
+            ``for`` loop.
+
+            :param int first: sequence number of the first
+                transaction to return (*optional*)
+            :param int limit: limit number of transactions to
+                return (*optional*)
+            :param array only_ops: Limit generator by these
+                operations (*optional*)
+            :param array exclude_ops: Exclude thse operations from
+                generator (*optional*)
+        """
+        asset_a=Asset(base)
+        asset_b=Asset(quote)
+
+        return  bitshares.rpc.get_market_history(
+            asset_a["id"],
+            asset_b["id"],
+            bucket_seconds,
+            start,
+            end,
+            api="history"
+        )
+
+def get_balance_objects( bitshares,addr ):
+
+        
+        return  bitshares.rpc.get_balance_objects(
+            addr,
+            api="database"
+        )
+
+def get_account_by_name( bitshares,name ):
+
+        
+        return  bitshares.rpc.get_account_by_name(
+            name,
+            api="database"
+        )
+def get_object( bitshares,id ):
+
+        
+        return  bitshares.rpc.get_object(
+            id,
+            api="database"
+        )
+
+
+def cancel_vesting(inst,balance_object,account=None):
+   """ cancel_vesting
+
+
+       :param str account: the account to cancel
+           to (defaults to ``default_account``)
+       :param str balance object: the balance object to cancel
+   """
+   if not account:
+       if "default_account" in inst.config:
+           account = inst.config["default_account"]
+   if not account:
+       raise ValueError("You need to provide an account")
+   account = Account(account)
+
+   kwargs = {
+       "fee": {"amount": 0, "asset_id": "1.3.0"},
+       "payer": account["id"],
+       "sender": account["id"],
+       "balance_object": balance_object,
+   }
+
+   op = operations.Cancel_vesting(**kwargs)
+
+
+   return inst.finalizeOp(op, account, "active")
+   
+
+#
+#  pts address:[ bin checksum[:4]]
+#      bin: ripemd160[ ver, sha256(pubkey)]
+#          ver:56 or 0.
+#          0 is used in cybex fork of witness node:libraries/chain/db_balance.cpp
+#      checksum: sha256 sha256 bin
+#  
+#  address(pts address):[bin checksum[:4]]    
+#      bin: ripemd160 pts address
+#      checksum: ripemd160 bin   
+#
+def pts_address(pubkey,prefix):
+         pubkeybin = PublicKey(pubkey,**{"prefix":prefix}).__bytes__()
+         #print(hexlify(pubkeybin),len(pubkeybin))
+         bin= "00"+hexlify(ripemd160(hexlify(hashlib.sha256(pubkeybin).digest()).decode('ascii'))).decode("ascii")
+         checksum=doublesha256(bin)
+
+         #print('bin',bin)
+         #print('csum1',checksum)
+         hex = bin+hexlify(checksum[:4]).decode('ascii')
+         #print('hex',hex)
+         hash=hexlify(ripemd160(hex)).decode('ascii')
+         #print('hash',hash)
+         checksum2=ripemd160(hash)
+         #print('csum2',checksum2)
+         b58= prefix+base58encode(hash + hexlify(checksum2[:4]).decode('ascii'))
+         #print('b58',b58)
+         return b58
+
+
diff -Nur -x __pycache__ bitshares_old/cybexobjects.py bitshares/cybexobjects.py
--- bitshares_old/cybexobjects.py       1970-01-01 08:00:00.000000000 +0800
+++ bitshares/cybexobjects.py   2018-04-20 11:33:16.782725243 +0800
@@ -0,0 +1,76 @@
+from collections import OrderedDict
+from graphenebase.types import (
+    Uint8, Int16, Uint16, Uint32, Uint64,
+    Varint32, Int64, String, Bytes, Void,
+    Array, PointInTime, Signature, Bool,
+    Set, Fixed_array, Optional, Static_variant,
+    Map, Id, VoteId,
+    ObjectId as GPHObjectId
+)
+from graphenebase.objects import GrapheneObject
+from bitsharesbase.account import PublicKey
+
+class linear_vesting_policy_initializer(GrapheneObject):
+    def __init__(self,begin_timestamp,vesting_cliff_seconds,vesting_duration_seconds):
+
+        super().__init__(OrderedDict( [
+             ("begin_timestamp",PointInTime(begin_timestamp)),
+             ("vesting_cliff_seconds",Uint32(vesting_cliff_seconds)),
+             ("vesting_duration_seconds",Uint32(vesting_duration_seconds))
+               ]))      
+
+
+class linear_vesting_policy(Static_variant):
+     def __init__(self,begin_timestamp,vesting_cliff_seconds,vesting_duration_seconds):
+         o = linear_vesting_policy_initializer(begin_timestamp,vesting_cliff_seconds,vesting_duration_seconds)
+         super().__init__(o,0)
+
+
+class cdd_vesting_policy_initializer(GrapheneObject):
+    def __init__(self,start_claim,vesting_seconds):
+        super().__init__(OrderedDict([
+            ("start_claim",PointInTime(start_claim)),
+            ("vesting_seconds",Uint32(vesting_seconds))
+               ]))   
+
+class cdd_vesting_policy(Static_variant):
+     def __init__(self,start_claim,vesting_seconds):
+         o = cdd_vesting_policy_initializer(start_claim,vesting_seconds)
+         super().__init__(o,1)
+
+def VestingPolicy(o):
+   if isinstance(o,(cdd_vesting_policy,linear_vesting_policy)):
+       return o
+ 
+   if isinstance(o,list):
+      if o[0]==0:
+         return linear_vesting_policy(o[1]["begin_timestamp"],o[1]["vesting_cliff_seconds"],o[1]["vesting_duration_seconds"])
+      else:
+         if o[0]==1:
+            return cdd_vesting_policy(o[1]["start_claim"],o[1]["vesting_seconds"])
+   else:
+      raise ValueError("policy")
+ 
+class cybex_ext_vesting(Static_variant):
+    def __init__(self,pubkey,period):
+        o= GrapheneObject(OrderedDict ([
+            ("vesting_period",Uint64(period)),
+            ("public_key",PublicKey(pubkey,**{"prefix":"CYB"})) 
+        ]))
+        super().__init__(o,1)
+
+
+def CybexExtension(o):
+   if isinstance(o,cybex_ext_vesting):
+       return o
+ 
+   if isinstance(o,list):
+      a=[]
+      for e in o:
+         if e[0]==1:
+             a.append( cybex_ext_vesting(e[1]["public_key"],e[1]["vesting_period"]))
+         else:
+             raise ValueError("not implemented yet.")
+      return Set(a)
+   else:
+      raise ValueError("Cybex extension")
EOF
cat >$BITSHARESBASE_PATCH_FILE <<EOF
diff -Nur -x __pycache__ bitsharesbase_old/cybexchain.py bitsharesbase/cybexchain.py
--- bitsharesbase_old/cybexchain.py     1970-01-01 08:00:00.000000000 +0800
+++ bitsharesbase/cybexchain.py 2018-04-20 18:46:26.258743421 +0800
@@ -0,0 +1,17 @@
+from bitshares.storage import configStorage
+from bitsharesbase.chains import known_chains
+from graphenebase.base58 import known_prefixes
+
+cybex_chain={
+        "chain_id": "",
+        "core_symbol": "CYB",
+        "prefix": "CYB"
+        }
+
+def cybex_config(node_rpc_endpoint = 'ws://127.0.0.1:8090',
+                 chain_id = '90be01e82b981c8f201c9a78a3d31f655743b29ff3274727b1439b093d04aa23'):
+   configStorage["prefix"]="CYB"
+   configStorage.config_defaults["node"]=node_rpc_endpoint
+   cybex_chain['chain_id'] = chain_id
+   known_chains["CYB"]= cybex_chain
+   known_prefixes.append("CYB")
diff -Nur -x __pycache__ bitsharesbase_old/operationids.py bitsharesbase/operationids.py
--- bitsharesbase_old/operationids.py   2018-04-04 15:34:42.956270217 +0800
+++ bitsharesbase/operationids.py       2018-04-20 11:35:10.448713470 +0800
@@ -47,6 +47,7 @@
     "fba_distribute",
     "bid_collateral",
     "execute_bid",
+    "cancel_vesting"
 ]
 operations = {o: ops.index(o) for o in ops}
 
diff -Nur -x __pycache__ bitsharesbase_old/operations.py bitsharesbase/operations.py
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
diff -Nur -x __pycache__ bitshares_old/bitshares.py bitshares/bitshares.py
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
diff -Nur -x __pycache__ bitshares_old/cybexlib.py bitshares/cybexlib.py
--- bitshares_old/cybexlib.py   1970-01-01 08:00:00.000000000 +0800
+++ bitshares/cybexlib.py       2018-04-24 17:56:19.605555973 +0800
@@ -0,0 +1,195 @@
+from bitshares import BitShares
+from bitsharesapi.bitsharesnoderpc import BitSharesNodeRPC
+from bitsharesbase.account import PrivateKey, PublicKey
+from bitsharesbase import transactions, operations
+from bitsharesbase.objects import Asset
+from bitshares.account import Account
+from binascii import hexlify, unhexlify
+from graphenebase.base58 import base58decode,base58encode,doublesha256,ripemd160, Base58
+import hashlib
+
+import logging
+import os
+import getpass
+
+log = logging.getLogger(__name__)
+
+def unlock(inst, *args, **kwargs):
+    if inst.wallet.created():
+        if "UNLOCK" in os.environ:
+            pwd = os.environ["UNLOCK"]
+        else:
+            pwd = getpass.getpass("Current Wallet Passphrase:")
+        inst.wallet.unlock(pwd)
+    else:
+        print("No wallet installed yet. Creating ...")
+        pwd = getpass.getpass("Wallet Encryption Passphrase:")
+        inst.wallet.create(pwd)
+
+
+
+def fill_order_history( bitshares, base, quote, limit=100,):
+        """ Returns a generator for individual account transactions. The
+            latest operation will be first. This call can be used in a
+            ``for`` loop.
+
+            :param asset base:  
+            :param asset quote:  
+            :param int limit: limit number of items to
+                return (*optional*)
+        """
+        
+        asset_a=Asset(base)
+        asset_b=Asset(quote)
+
+        return bitshares.rpc.get_fill_order_history(
+            asset_a["id"],
+            asset_b["id"],
+            limit,
+            api="history"
+        )
+
+
+
+
+def market_history( bitshares, base,quote,bucket_seconds,start,end):
+        """ Returns a generator for individual account transactions. The
+            latest operation will be first. This call can be used in a
+            ``for`` loop.
+
+            :param int first: sequence number of the first
+                transaction to return (*optional*)
+            :param int limit: limit number of transactions to
+                return (*optional*)
+            :param array only_ops: Limit generator by these
+                operations (*optional*)
+            :param array exclude_ops: Exclude thse operations from
+                generator (*optional*)
+        """
+        asset_a=Asset(base)
+        asset_b=Asset(quote)
+
+        return  bitshares.rpc.get_market_history(
+            asset_a["id"],
+            asset_b["id"],
+            bucket_seconds,
+            start,
+            end,
+            api="history"
+        )
+
+def get_balance_objects( bitshares,addr ):
+
+        
+        return  bitshares.rpc.get_balance_objects(
+            addr,
+            api="database"
+        )
+
+def get_account_by_name( bitshares,name ):
+
+        
+        return  bitshares.rpc.get_account_by_name(
+            name,
+            api="database"
+        )
+def get_object( bitshares,id ):
+
+        
+        return  bitshares.rpc.get_object(
+            id,
+            api="database"
+        )
+
+
+def cancel_vesting(inst,balance_object,account=None):
+   """ cancel_vesting
+
+
+       :param str account: the account to cancel
+           to (defaults to ``default_account``)
+       :param str balance object: the balance object to cancel
+   """
+   if not account:
+       if "default_account" in inst.config:
+           account = inst.config["default_account"]
+   if not account:
+       raise ValueError("You need to provide an account")
+   account = Account(account)
+
+   kwargs = {
+       "fee": {"amount": 0, "asset_id": "1.3.0"},
+       "payer": account["id"],
+       "sender": account["id"],
+       "balance_object": balance_object,
+   }
+
+   op = operations.Cancel_vesting(**kwargs)
+
+
+   return inst.finalizeOp(op, account, "active")
+   
+
+def issue_asset(inst,account,issue_to_account,asset_to_issue, amount,memo,**_kwargs):
+   """ issue asset
+
+       :param str account: (optional) the account of issuer
+           to (defaults to ``default_account``)
+       :param str account: (optional) the account of asset receiver
+       :param object id:  id of the asset to issue
+       :param float amount: amount of the asset to issue
+       :param str memo: memo
+   """
+   if not account:
+       if "default_account" in config:
+           account = config["default_account"]
+   if not account:
+       raise ValueError("You need to provide an account")
+   acc = Account(account)
+   issue_to_acc = Account(issue_to_account)
+   asset=Asset(asset_id=asset_to_issue, amount=amount)
+
+   kwargs = {
+       "fee": {"amount": 0, "asset_id": "1.3.0"},
+       "issuer": acc["id"],
+       "issue_to_account": issue_to_acc["id"],
+       "asset_to_issue": asset,
+       "memo": memo,
+   }
+   if "extensions" in _kwargs:
+         kwargs["extensions"]=_kwargs["extensions"]
+
+   op = operations.Asset_issue(**kwargs)
+
+   return inst.finalizeOp(op, account, "active")
+
+#
+#  pts address:[ bin checksum[:4]]
+#      bin: ripemd160[ ver, sha256(pubkey)]
+#          ver:56 or 0.
+#          0 is used in cybex fork of witness node:libraries/chain/db_balance.cpp
+#      checksum: sha256 sha256 bin
+#  
+#  address(pts address):[bin checksum[:4]]    
+#      bin: ripemd160 pts address
+#      checksum: ripemd160 bin   
+#
+def pts_address(pubkey,prefix):
+         pubkeybin = PublicKey(pubkey,**{"prefix":prefix}).__bytes__()
+         #print(hexlify(pubkeybin),len(pubkeybin))
+         bin= "00"+hexlify(ripemd160(hexlify(hashlib.sha256(pubkeybin).digest()).decode('ascii'))).decode("ascii")
+         checksum=doublesha256(bin)
+
+         #print('bin',bin)
+         #print('csum1',checksum)
+         hex = bin+hexlify(checksum[:4]).decode('ascii')
+         #print('hex',hex)
+         hash=hexlify(ripemd160(hex)).decode('ascii')
+         #print('hash',hash)
+         checksum2=ripemd160(hash)
+         #print('csum2',checksum2)
+         b58= prefix+base58encode(hash + hexlify(checksum2[:4]).decode('ascii'))
+         #print('b58',b58)
+         return b58
+
+
diff -Nur -x __pycache__ bitshares_old/cybexobjects.py bitshares/cybexobjects.py
--- bitshares_old/cybexobjects.py       1970-01-01 08:00:00.000000000 +0800
+++ bitshares/cybexobjects.py   2018-04-20 10:47:28.602662623 +0800
@@ -0,0 +1,76 @@
+from collections import OrderedDict
+from graphenebase.types import (
+    Uint8, Int16, Uint16, Uint32, Uint64,
+    Varint32, Int64, String, Bytes, Void,
+    Array, PointInTime, Signature, Bool,
+    Set, Fixed_array, Optional, Static_variant,
+    Map, Id, VoteId,
+    ObjectId as GPHObjectId
+)
+from graphenebase.objects import GrapheneObject
+from bitsharesbase.account import PublicKey
+
+class linear_vesting_policy_initializer(GrapheneObject):
+    def __init__(self,begin_timestamp,vesting_cliff_seconds,vesting_duration_seconds):
+
+        super().__init__(OrderedDict( [
+             ("begin_timestamp",PointInTime(begin_timestamp)),
+             ("vesting_cliff_seconds",Uint32(vesting_cliff_seconds)),
+             ("vesting_duration_seconds",Uint32(vesting_duration_seconds))
+               ]))      
+
+
+class linear_vesting_policy(Static_variant):
+     def __init__(self,begin_timestamp,vesting_cliff_seconds,vesting_duration_seconds):
+         o = linear_vesting_policy_initializer(begin_timestamp,vesting_cliff_seconds,vesting_duration_seconds)
+         super().__init__(o,0)
+
+
+class cdd_vesting_policy_initializer(GrapheneObject):
+    def __init__(self,start_claim,vesting_seconds):
+        super().__init__(OrderedDict([
+            ("start_claim",PointInTime(start_claim)),
+            ("vesting_seconds",Uint32(vesting_seconds))
+               ]))   
+
+class cdd_vesting_policy(Static_variant):
+     def __init__(self,start_claim,vesting_seconds):
+         o = cdd_vesting_policy_initializer(start_claim,vesting_seconds)
+         super().__init__(o,1)
+
+def VestingPolicy(o):
+   if isinstance(o,(cdd_vesting_policy,linear_vesting_policy)):
+       return o
+ 
+   if isinstance(o,list):
+      if o[0]==0:
+         return linear_vesting_policy(o[1]["begin_timestamp"],o[1]["vesting_cliff_seconds"],o[1]["vesting_duration_seconds"])
+      else:
+         if o[0]==1:
+            return cdd_vesting_policy(o[1]["start_claim"],o[1]["vesting_seconds"])
+   else:
+      raise ValueError("policy")
+ 
+class cybex_ext_vesting(Static_variant):
+    def __init__(self,pubkey,period):
+        o= GrapheneObject(OrderedDict ([
+            ("vesting_period",Uint64(period)),
+            ("public_key",PublicKey(pubkey,**{"prefix":"CYB"})) 
+        ]))
+        super().__init__(o,1)
+
+
+def CybexExtension(o):
+   if isinstance(o,cybex_ext_vesting):
+       return o
+ 
+   if isinstance(o,list):
+      a=[]
+      for e in o:
+         if e[0]==1:
+             a.append( cybex_ext_vesting(e[1]["public_key"],e[1]["vesting_period"]))
+         else:
+             raise ValueError("not implemented yet.")
+      return Set(a)
+   else:
+      raise ValueError("Cybex extension")
EOF
cat >$BITSHARESBASE_PATCH_FILE <<EOF
diff -Nur -x __pycache__ bitsharesbase_old/cybexchain.py bitsharesbase/cybexchain.py
--- bitsharesbase_old/cybexchain.py     1970-01-01 08:00:00.000000000 +0800
+++ bitsharesbase/cybexchain.py 2018-04-20 18:40:18.448253805 +0800
@@ -0,0 +1,17 @@
+from bitshares.storage import configStorage
+from bitsharesbase.chains import known_chains
+from graphenebase.base58 import known_prefixes
+
+cybex_chain={
+        "chain_id": "",
+        "core_symbol": "CYB",
+        "prefix": "CYB"
+        }
+
+def cybex_config(node_rpc_endpoint = 'ws://127.0.0.1:8090',
+                 chain_id = '90be01e82b981c8f201c9a78a3d31f655743b29ff3274727b1439b093d04aa23'):
+   configStorage["prefix"]="CYB"
+   configStorage.config_defaults["node"]=node_rpc_endpoint
+   cybex_chain['chain_id'] = chain_id
+   known_chains["CYB"]= cybex_chain
+   known_prefixes.append("CYB")
diff -Nur -x __pycache__ bitsharesbase_old/operationids.py bitsharesbase/operationids.py
--- bitsharesbase_old/operationids.py   2018-04-04 14:24:06.982826232 +0800
+++ bitsharesbase/operationids.py       2018-04-24 17:58:52.948237621 +0800
@@ -47,6 +47,60 @@
     "fba_distribute",
     "bid_collateral",
     "execute_bid",
+    "reserved47",
+    "reserved48",
+    "reserved49",
+    "reserved50",
+    "reserved51",
+    "reserved52",
+    "reserved53",
+    "reserved54",
+    "reserved55",
+    "reserved56",
+    "reserved57",
+    "reserved58",
+    "reserved59",
+    "reserved60",
+    "reserved61",
+    "reserved62",
+    "reserved63",
+    "reserved64",
+    "reserved65",
+    "reserved66",
+    "reserved67",
+    "reserved68",
+    "reserved69",
+    "reserved70",
+    "reserved71",
+    "reserved72",
+    "reserved73",
+    "reserved74",
+    "reserved75",
+    "reserved76",
+    "reserved77",
+    "reserved78",
+    "reserved79",
+    "reserved80",
+    "reserved81",
+    "reserved82",
+    "reserved83",
+    "reserved84",
+    "reserved85",
+    "reserved86",
+    "reserved87",
+    "reserved88",
+    "reserved89",
+    "reserved90",
+    "reserved91",
+    "reserved92",
+    "reserved93",
+    "reserved94",
+    "reserved95",
+    "reserved96",
+    "reserved97",
+    "reserved98",
+    "reserved99",
+    "cancel_vesting"
 ]
 operations = {o: ops.index(o) for o in ops}
 
diff -Nur -x __pycache__ bitsharesbase_old/operations.py bitsharesbase/operations.py
--- bitsharesbase_old/operations.py     2018-04-04 14:24:06.982826232 +0800
+++ bitsharesbase/operations.py 2018-04-24 18:10:30.348432860 +0800
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
 
 
@@ -151,16 +158,22 @@
             if len(args) == 1 and len(kwargs) == 0:
                 kwargs = args[0]
             if "memo" in kwargs and kwargs["memo"]:
-                memo = Optional(Memo(prefix=prefix, **kwargs["memo"]))
+                memo = Optional(Memo(kwargs["memo"],prefix=prefix))
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
                 ('issuer', ObjectId(kwargs["issuer"], "account")),
                 ('asset_to_issue', Asset(kwargs["asset_to_issue"])),
                 ('issue_to_account', ObjectId(kwargs["issue_to_account"], "account")),
                 ('memo', memo),
-                ('extensions', Set([])),
+                ('extensions', extensions),
             ]))
 
 
@@ -562,3 +575,17 @@
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
