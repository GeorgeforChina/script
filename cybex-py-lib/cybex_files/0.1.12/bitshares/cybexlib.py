from bitshares import BitShares
from bitsharesapi.bitsharesnoderpc import BitSharesNodeRPC
from bitsharesbase.account import PrivateKey, PublicKey
from bitsharesbase import transactions, operations
from bitshares.asset import Asset
from bitshares.account import Account
from binascii import hexlify, unhexlify
from graphenebase.base58 import base58decode,base58encode,doublesha256,ripemd160, Base58
import hashlib

import logging
import os
import getpass

log = logging.getLogger(__name__)

def unlock(inst, *args, **kwargs):
    if inst.wallet.created():
        if "UNLOCK" in os.environ:
            pwd = os.environ["UNLOCK"]
        else:
            pwd = getpass.getpass("Current Wallet Passphrase:")
        inst.wallet.unlock(pwd)
    else:
        print("No wallet installed yet. Creating ...")
        pwd = getpass.getpass("Wallet Encryption Passphrase:")
        inst.wallet.create(pwd)



def fill_order_history( bitshares, base, quote, limit=100,):
        """ Returns a generator for individual account transactions. The
            latest operation will be first. This call can be used in a
            ``for`` loop.

            :param asset base:  
            :param asset quote:  
            :param int limit: limit number of items to
                return (*optional*)
        """
        
        asset_a=Asset(base)
        asset_b=Asset(quote)

        return bitshares.rpc.get_fill_order_history(
            asset_a["id"],
            asset_b["id"],
            limit,
            api="history"
        )




def market_history( bitshares, base,quote,bucket_seconds,start,end):
        """ Returns a generator for individual account transactions. The
            latest operation will be first. This call can be used in a
            ``for`` loop.

            :param int first: sequence number of the first
                transaction to return (*optional*)
            :param int limit: limit number of transactions to
                return (*optional*)
            :param array only_ops: Limit generator by these
                operations (*optional*)
            :param array exclude_ops: Exclude thse operations from
                generator (*optional*)
        """
        asset_a=Asset(base)
        asset_b=Asset(quote)

        return  bitshares.rpc.get_market_history(
            asset_a["id"],
            asset_b["id"],
            bucket_seconds,
            start,
            end,
            api="history"
        )

def get_balance_objects( bitshares,addr ):

        
        return  bitshares.rpc.get_balance_objects(
            addr,
            api="database"
        )

def get_account_by_name( bitshares,name ):

        
        return  bitshares.rpc.get_account_by_name(
            name,
            api="database"
        )
def get_object( bitshares,id ):

        
        return  bitshares.rpc.get_object(
            id,
            api="database"
        )


def cancel_vesting(inst,balance_object,account=None):
   """ cancel_vesting


       :param str account: the account to cancel
           to (defaults to ``default_account``)
       :param str balance object: the balance object to cancel
   """
   if not account:
       if "default_account" in inst.config:
           account = inst.config["default_account"]
   if not account:
       raise ValueError("You need to provide an account")
   account = Account(account)

   kwargs = {
       "fee": {"amount": 0, "asset_id": "1.3.0"},
       "payer": account["id"],
       "sender": account["id"],
       "balance_object": balance_object,
   }

   op = operations.Cancel_vesting(**kwargs)


   return inst.finalizeOp(op, account, "active")
   

#
#  pts address:[ bin checksum[:4]]
#      bin: ripemd160[ ver, sha256(pubkey)]
#          ver:56 or 0.
#          0 is used in cybex fork of witness node:libraries/chain/db_balance.cpp
#      checksum: sha256 sha256 bin
#  
#  address(pts address):[bin checksum[:4]]    
#      bin: ripemd160 pts address
#      checksum: ripemd160 bin   
#
def pts_address(pubkey,prefix):
         pubkeybin = PublicKey(pubkey,**{"prefix":prefix}).__bytes__()
         #print(hexlify(pubkeybin),len(pubkeybin))
         bin= "00"+hexlify(ripemd160(hexlify(hashlib.sha256(pubkeybin).digest()).decode('ascii'))).decode("ascii")
         checksum=doublesha256(bin)

         #print('bin',bin)
         #print('csum1',checksum)
         hex = bin+hexlify(checksum[:4]).decode('ascii')
         #print('hex',hex)
         hash=hexlify(ripemd160(hex)).decode('ascii')
         #print('hash',hash)
         checksum2=ripemd160(hash)
         #print('csum2',checksum2)
         b58= prefix+base58encode(hash + hexlify(checksum2[:4]).decode('ascii'))
         #print('b58',b58)
         return b58


