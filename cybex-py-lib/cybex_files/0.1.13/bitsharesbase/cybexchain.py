from bitshares.storage import configStorage
from bitsharesbase.chains import known_chains
from graphenebase.base58 import known_prefixes

cybex_chain={
        "chain_id": "90be01e82b981c8f201c9a78a3d31f655743b29ff3274727b1439b093d04aa23",
        "core_symbol": "CYB",
        "prefix": "CYB"
        }

def cybex_config():
   configStorage["prefix"]="CYB"
   configStorage.config_defaults["node"]='ws://127.0.0.1:8090'
   known_chains["CYB"]= cybex_chain
   known_prefixes.append("CYB")
