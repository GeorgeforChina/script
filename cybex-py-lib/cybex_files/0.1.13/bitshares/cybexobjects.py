from collections import OrderedDict
from graphenebase.types import (
    Uint8, Int16, Uint16, Uint32, Uint64,
    Varint32, Int64, String, Bytes, Void,
    Array, PointInTime, Signature, Bool,
    Set, Fixed_array, Optional, Static_variant,
    Map, Id, VoteId,
    ObjectId as GPHObjectId
)
from graphenebase.objects import GrapheneObject
from bitsharesbase.account import PublicKey

class linear_vesting_policy_initializer(GrapheneObject):
    def __init__(self,begin_timestamp,vesting_cliff_seconds,vesting_duration_seconds):

        super().__init__(OrderedDict( [
             ("begin_timestamp",PointInTime(begin_timestamp)),
             ("vesting_cliff_seconds",Uint32(vesting_cliff_seconds)),
             ("vesting_duration_seconds",Uint32(vesting_duration_seconds))
               ]))      


class linear_vesting_policy(Static_variant):
     def __init__(self,begin_timestamp,vesting_cliff_seconds,vesting_duration_seconds):
         o = linear_vesting_policy_initializer(begin_timestamp,vesting_cliff_seconds,vesting_duration_seconds)
         super().__init__(o,0)


class cdd_vesting_policy_initializer(GrapheneObject):
    def __init__(self,start_claim,vesting_seconds):
        super().__init__(OrderedDict([
            ("start_claim",PointInTime(start_claim)),
            ("vesting_seconds",Uint32(vesting_seconds))
               ]))   

class cdd_vesting_policy(Static_variant):
     def __init__(self,start_claim,vesting_seconds):
         o = cdd_vesting_policy_initializer(start_claim,vesting_seconds)
         super().__init__(o,1)

def VestingPolicy(o):
   if isinstance(o,(cdd_vesting_policy,linear_vesting_policy)):
       return o
 
   if isinstance(o,list):
      if o[0]==0:
         return linear_vesting_policy(o[1]["begin_timestamp"],o[1]["vesting_cliff_seconds"],o[1]["vesting_duration_seconds"])
      else:
         if o[0]==1:
            return cdd_vesting_policy(o[1]["start_claim"],o[1]["vesting_seconds"])
   else:
      raise ValueError("policy")
 
class cybex_ext_vesting(Static_variant):
    def __init__(self,pubkey,period):
        o= GrapheneObject(OrderedDict ([
            ("vesting_period",Uint64(period)),
            ("public_key",PublicKey(pubkey,**{"prefix":"CYB"})) 
        ]))
        super().__init__(o,1)


def CybexExtension(o):
   if isinstance(o,cybex_ext_vesting):
       return o
 
   if isinstance(o,list):
      a=[]
      for e in o:
         if e[0]==1:
             a.append( cybex_ext_vesting(e[1]["public_key"],e[1]["vesting_period"]))
         else:
             raise ValueError("not implemented yet.")
      return Set(a)
   else:
      raise ValueError("Cybex extension")
