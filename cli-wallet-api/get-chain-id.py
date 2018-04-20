import subprocess
import json
import argparse

parser = argparse.ArgumentParser(description="get chain id")
parser.add_argument("-p", "--port", metavar="PORT", default=8090, type=int, help="port of wallet rpc endpoint")
opts = parser.parse_args()



arg= {"jsonrpc": "2.0", "method": "get_chain_properties", "params": [], "id": 1}

url= "http://127.0.0.1:"+str(opts.port)+"/rpc"
#print(url)
ret=subprocess.check_output(["curl", "--data" ,json.dumps(arg),url ]).decode("utf-8") 
#print(ret)

obj=json.loads(ret)
print(obj["result"]["chain_id"])

