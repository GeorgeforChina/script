from bitshares.cybexlib import unlock
from bitshares.account import Account
from bitshares.asset import Asset
from bitshares import BitShares
from bitsharesbase.cybexchain import cybex_config,cybex_network

NODE_WS_ENDPOINT = 'ws://101.132.155.237:8090'
CHAIN_ID = '90be01e82b981c8f201c9a78a3d31f655743b29ff3274727b1439b093d04aa23'

FROM_ACCOUNT = 'from-account-name'
FROM_ACCOUNT_ACTIVE_PRIVATE_KEY = 'your active private key'
WALLET_PASSWD = '123456'
TO_ACCOUNT = 'to-account-name'
ASSET_NAME = 'CYB'
ASSET_AMOUNT = 100

def transfer_asset():
    cybex_config(node_rpc_endpoint = NODE_WS_ENDPOINT, chain_id = CHAIN_ID)

    net = BitShares(node = NODE_WS_ENDPOINT, **{'prefix': 'cyb'})

    cybex_network(net)

    unlock(net)

    try:
        net.wallet.addPrivateKey(FROM_ACCOUNT_ACTIVE_PRIVATE_KEY)
    except Exception as e:
        pass

    net.wallet.unlock(WALLET_PASSWD)

    acc = Account(FROM_ACCOUNT, bitshares_instance = net)

    net.transfer(TO_ACCOUNT, ASSET_AMOUNT, ASSET_NAME, 'memo string', account = acc)

if __name__ == '__main__':
    transfer_asset()
