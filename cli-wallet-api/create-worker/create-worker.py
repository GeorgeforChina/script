from websocket import create_connection
import json
import sys
import argparse
sys.path.append("..")
from passwd import get_pass

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
    parser = argparse.ArgumentParser(description="create workder")
    parser.add_argument("-p", "--port", metavar="PORT", default=8091, type=int, help="port of wallet rpc endpoint")
    parser.add_argument("-u", "--url", metavar="URL", default="dex.cybex.io", type=str, help="url for key create worker")
    parser.add_argument("owner_account");
    parser.add_argument("work_begin_date");
    parser.add_argument("work_end_date");
    parser.add_argument("daily_pay");
    parser.add_argument("name");
    opts = parser.parse_args()
    key={}

    ws = create_connection("ws://127.0.0.1:"+str(opts.port))
    passwd = get_pass()
    req={"id":1,"method": "call", "params": [0,"unlock", [passwd] ]}
    call(ws,req)
    req={"id":2,"method": "call", "params": [0, "create_worker",[opts.owner_account,opts.work_begin_date,opts.work_end_date,opts.daily_pay,opts.name,opts.url,{"type":"vesting","pay_vesting_period_days":1},True ] ]}
    call(ws,req)

    ws.close()

    return

if __name__ == "__main__":
    main()
