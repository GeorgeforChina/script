from bitshares.storage import configStorage
from bitsharesbase.chains import known_chains
from graphenebase.base58 import known_prefixes

cybex_chain={
        "chain_id": "",
        "core_symbol": "CYB",
        "prefix": "CYB"
        }

def cybex_config(node_rpc_endpoint = 'ws://127.0.0.1:8090',
                 chain_id = '90be01e82b981c8f201c9a78a3d31f655743b29ff3274727b1439b093d04aa23'):
   configStorage["prefix"]="CYB"
   configStorage.config_defaults["node"]=node_rpc_endpoint
   cybex_chain['chain_id'] = chain_id
   known_chains["CYB"]= cybex_chain
   known_prefixes.append("CYB")
