from bitshares.cybexlib import unlock
from bitshares.account import Account
from bitshares.asset import Asset
from bitshares.market import Market
from bitshares import BitShares
from bitsharesbase.cybexchain import cybex_config,cybex_network

NODE_WS_ENDPOINT = 'ws://127.0.0.1:8090'
CHAIN_ID = '90be01e82b981c8f201c9a78a3d31f655743b29ff3274727b1439b093d04aa23'

def order_and_cancel():
    cybex_config(node_rpc_endpoint = NODE_WS_ENDPOINT, chain_id = CHAIN_ID)
    
    net = BitShares(node = NODE_WS_ENDPOINT, **{'prefix':'CYB'})
    
    cybex_network(net)
    
    unlock(net)

    try:
        net.wallet.addPrivateKey('your active private key')
    except Exception as e:
        pass
    
    net.wallet.unlock('your wallet unlock password')
    
    account = Account('account name', bitshares_instance = net)
    
    market = Market(base = Asset('CYB'), quote = Asset('JADE.ETH'), bitshares_instance = net)

    # buy 0.001 JADE.ETH at price JADE.ETH:CYB 1000, expire in 60 seconds
    # market.sell will do the sell operation
    market.buy(1000, 0.001, 60, False, 'account name', 'Head') 
    
    # query open orders
    for order in account.openorders:
        base_amount = order['base'].amount
        base_symbol = order['base'].symbol
        quote_amount = order['quote'].amount
        quote_symbol = order['quote'].symbol
        order_number = order['id']
        print('{}:{}--{}/{}'.format(quote_symbol, base_symbol, quote_amount, base_amount))
        # cancel order
        market.cancel(order_number, 'account name')

if __name__ == '__main__':
    order_and_cancel()
