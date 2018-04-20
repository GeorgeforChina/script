from websocket import create_connection
import json
import sys
import argparse

def gen_key( secret,account):
  key={}
  istr = "owner-"+ account
  prod_str = subprocess.check_output(["bin/get_dev_key", secret, istr]).decode("utf-8")
  prod = json.loads(prod_str)
  key["owner-key"]=prod[0]
  istr = "active-"+ account
  prod_str = subprocess.check_output(["bin/get_dev_key", secret, istr]).decode("utf-8")
  prod = json.loads(prod_str)
  key["active-key"]=prod[0]
  return key


def call(ws,req):
  print "Sent"+json.dumps(req,sort_keys=True)
  ws.send(json.dumps(req,sort_keys=True))
  print "Receiving..."
  result =  ws.recv()
  #print "Received '%s'" % result
  response = json.loads(result)
  #print "return:" +json.dumps(response )
  if response.get("error"):
      print "error" + json.dumps(response.get("error"))
  else:
      print "return:" +json.dumps(response.get("result") )
  return response.get("result")


def main():
    parser = argparse.ArgumentParser(description="create acount")
    parser.add_argument("-p", "--port", metavar="PORT", default=8091, type=int, help="port of wallet rpc endpoint")
    parser.add_argument("account");
    parser.add_argument("key");
    parser.add_argument("file");
    opts = parser.parse_args()
    key={}


    with open(opts.key, "r") as f:
         account_key = json.load(f)

    ws = create_connection("ws://127.0.0.1:"+str(opts.port))

    req={"id":2,"method": "call", "params": [0,"unlock",["123456"] ]}
    call(ws,req)
    req={"id":2,"method": "call", "params": [0,"import_key",[opts.account,account_key["active-key"]["private_key"]] ]}
    call(ws,req)
    req={"id":2,"method": "call", "params": [0,"import_key",[opts.account,account_key["owner-key"]["private_key"]] ]}
    call(ws,req)
    req={"id":2,"method": "call", "params": [0,"save_wallet_file",[opts.file ] ]}
    call(ws,req)

    ws.close()

    return

if __name__ == "__main__":
    main()
