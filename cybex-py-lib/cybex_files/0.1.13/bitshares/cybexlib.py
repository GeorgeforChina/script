from bitshares import BitShares
from bitsharesapi.bitsharesnoderpc import BitSharesNodeRPC
from bitsharesbase.account import PrivateKey, PublicKey
from bitsharesbase import transactions, operations
from bitshares.asset import Asset
from bitshares.account import Account
from binascii import hexlify, unhexlify
from graphenebase.base58 import base58decode,base58encode,doublesha256,ripemd160, Base58
from graphenebase.account import  PublicKey as GPHPublicKey
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

def lookup_asset_symbols( bitshares,symbols ):


        return  bitshares.rpc.lookup_asset_symbols(
            symbols,
            api="database"
        )

def get_crowdfund_objects( bitshares,id ):

        
        return  bitshares.rpc.get_crowdfund_objects(
            id,
            api="database"
        )

def get_crowdfund_contract_objects( bitshares,id ):

        
        return  bitshares.rpc.get_crowdfund_contract_objects(
            id,
            api="database"
        )

def list_crowdfund_objects( bitshares,id,limit ):

        
        return  bitshares.rpc.list_crowdfund_objects(
            id,limit,
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


def withdraw_crowdfund(inst,crowdfund_contract,account=None):
   """ withdraw_crowdfund
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
       "buyer": account["id"],
       "crowdfund_contract": crowdfund_contract
   }

   op = operations.Withdraw_crowdfund(**kwargs)

   return inst.finalizeOp(op, account, "active")

def participate_crowdfund(inst,crowdfund,valuation,cap,account=None):
   """ participate_crowdfund
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
       "buyer": account["id"],
       "valuation":valuation,
       "cap":cap,
       "crowdfund": crowdfund
   }

   op = operations.Participate_crowdfund(**kwargs)

   return inst.finalizeOp(op, account, "active")


def initiate_crowdfund(inst,asset_id,t,u,account=None):
   """ initiate_crowdfund
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
       "owner": account["id"],
       "asset_id":asset_id,
       "t": t,
       "u": u
   }

   op = operations.Initiate_crowdfund(**kwargs)

   return inst.finalizeOp(op, account, "active")

def issue_asset(inst,issue_to_account,to_issue_asset,amount,memo=None,account=None,**kwargs):
   """ issue_asset


       :param str account: the account to cancel
           to (defaults to ``default_account``)
   """
   if not account:
       if "default_account" in inst.config:
           account = inst.config["default_account"]
   if not account:
       raise ValueError("You need to provide an account")
   account = Account(account)

   if 'extensions' in kwargs :
        extensions=kwargs['extensions']
   else:
        extensions=Set([])
   print(extensions)
   asset_to_issue={"amount": amount, "asset_id":to_issue_asset }
   kwargs = {
                'fee':{"amount": 0, "asset_id": "1.3.0"},
                'issuer':account["id"],
                'asset_to_issue':asset_to_issue,
                'issue_to_account': issue_to_account,
                'memo':memo,
                'extensions':extensions
   }

   op = operations.Asset_issue(**kwargs)


   return inst.finalizeOp(op, account, "active")

def call_order_update(inst,delta_collateral,delta_debt,account=None):
   """ call_order_update 

       :param str account: the account to cancel
           to (defaults to ``default_account``)
   """
   if not account:
       if "default_account" in inst.config:
           account = inst.config["default_account"]
   if not account:
       raise ValueError("You need to provide an account")
   account = Account(account)

   kwargs = {
                'fee':{"amount": 0, "asset_id": "1.3.0"},
                'funding_account':account["id"],
                'delta_collateral':delta_collateral,
                'delta_debt':delta_debt,
   }

   op = operations.Call_order_update(**kwargs)

   return inst.finalizeOp(op, account, "active")


def  create_asset(inst,symbol,precision,is_prediction_market=False,account=None,**kwargs):
   """ create_asset
   """
   key={}
   perm = {}
   perm["charge_market_fee"] = 0x01
   perm["white_list"] = 0x02
   perm["override_authority"] = 0x04
   perm["transfer_restricted"] = 0x08
   perm["disable_force_settle"] = 0x10
   perm["global_settle"] = 0x20
   perm["disable_confidential"] = 0x40
   perm["witness_fed_asset"] = 0x80
   perm["committee_fed_asset"] = 0x100

   permissions = {"charge_market_fee" : False,
                  "white_list" : True,
                  "override_authority" : True,
                  "transfer_restricted" : True,
                  "disable_force_settle" : False,
                  "global_settle" : True,
                  "disable_confidential" : True,
                  "witness_fed_asset" : False,
                  "committee_fed_asset" : False,
                  }
   flags       = {"charge_market_fee" : False,
                  "white_list" : False,
                  "override_authority" : False,
                  "transfer_restricted" : False,
                  "disable_force_settle" : False,
                  "global_settle" : False,
                  "disable_confidential" : False,
                  "witness_fed_asset" : False,
                  "committee_fed_asset" : False,
                  }
   permissions_int = 0
   for p in permissions :
       if permissions[p]:
           permissions_int += perm[p]
   flags_int = 0
   for p in permissions :
       if flags[p]:
           flags_int += perm[p]

   extension= []
   options = {"max_supply" : 1000000000000000,
              "market_fee_percent" : 0,
              "max_market_fee" : 0,
              "issuer_permissions" : permissions_int,
              "flags" : flags_int,
              "precision" : precision,
              "core_exchange_rate" : {
                  "base": {
                      "amount": 10,
                      "asset_id": "1.3.0"},
                  "quote": {
                      "amount": 10,
                      "asset_id": "1.3.1"}},
              "whitelist_authorities" : [],
              "blacklist_authorities" : [],
              "whitelist_markets" : [],
              "blacklist_markets" : [],
              "description" : "My fancy description",
              "extensions" : extension
              }

   if not account:
       if "default_account" in inst.config:
           account = inst.config["default_account"]
   if not account:
       raise ValueError("You need to provide an account")
   account = Account(account)
 
   if 'common_options' in kwargs:
         common_options=kwargs['common_options']
   else:
         common_options=options
 
   if 'bitasset_options' in kwargs:
         bitasset_options=kwargs['bitasset_options']
   else:
         bitasset_options=None

   kwargs = {
                'fee': {"amount": 0, "asset_id": "1.3.0"},
                'issuer': account["id"],
                'symbol': symbol,
                'precision': precision,
                'common_options': common_options,
                'is_prediction_market': is_prediction_market
   }
   if bitasset_options:
        kwargs['bitasset_opts'] = bitasset_options 

   op = operations.Asset_create(**kwargs)


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
def pts_address(pubkey,compressed,ver,prefix):
         if compressed:
            pubkeybin = PublicKey(pubkey,**{"prefix":prefix}).__bytes__()
         else:
            pubkeybin = unhexlify(PublicKey(pubkey,**{"prefix":prefix}).unCompressed())

         #print(hexlify(pubkeybin),len(pubkeybin))
         bin='%02x'%(ver) +hexlify(ripemd160(hexlify(hashlib.sha256(pubkeybin).digest()).decode('ascii'))).decode("ascii")
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




