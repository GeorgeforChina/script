from bitshares.asset import Asset
from bitshares.market import Market
from bitshares import BitShares
from bitsharesbase.cybexchain import cybex_config

NODE_WS_ENDPOINT = 'ws://127.0.0.1:8090'
CHAIN_ID = '90be01e82b981c8f201c9a78a3d31f655743b29ff3274727b1439b093d04aa23'

def fetch_market():
    cybex_config(node_rpc_endpoint = NODE_WS_ENDPOINT, chain_id = CHAIN_ID)

    net = BitShares(node = NODE_WS_ENDPOINT, **{'prefix':'CYB'})

    net.wallet.unlock('123456')

    m = Market(base = Asset('CYB'), quote = Asset('JADE.ETH'), bitshares_instance = net)

    tick = m.ticker()

    latest = tick['latest']

    price = latest['base'].amount / latest['quote'].amount

    print('JADE.ETH:CYB = {}'.format(price))

if __name__ == '__main__':
    fetch_market()
