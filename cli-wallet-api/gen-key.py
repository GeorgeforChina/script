from websocket import create_connection
import json
import sys
import argparse
import subprocess

def dump_json(obj, out, pretty):
    if pretty:
        json.dump(obj, out, indent=2, sort_keys=True)
    else:
        json.dump(obj, out, separators=(",", ":"), sort_keys=True)
    return

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

def gen_wit_key( secret,account):
  key={}
  istr = "wit-owner-"+ account
  prod_str = subprocess.check_output(["bin/get_dev_key", secret, istr]).decode("utf-8")
  prod = json.loads(prod_str)
  key["owner-key"]=prod[0]
  istr = "wit-active-"+ account
  prod_str = subprocess.check_output(["bin/get_dev_key", secret, istr]).decode("utf-8")
  prod = json.loads(prod_str)
  key["active-key"]=prod[0]
  istr = "wit-block-signing-"+ account
  prod_str = subprocess.check_output(["bin/get_dev_key", secret, istr]).decode("utf-8")
  prod = json.loads(prod_str)
  key["signing-key"]=prod[0]
  return key


def main():
    parser = argparse.ArgumentParser(description="create acount owner and active keys")
    parser.add_argument("-o", "--output", metavar="OUT", default="-", help="output filename (default: stdout)")
    parser.add_argument('-w', action="store_true",default=False,help="initial witness")
    parser.add_argument("secret");
    parser.add_argument("account");
    opts = parser.parse_args()
    if opts.w:
       key=gen_wit_key(opts.secret,opts.account)
    else:
       key=gen_key(opts.secret,opts.account)
    if opts.output == "-":
        dump_json( key, sys.stdout, True )
        sys.stdout.flush()
    else:
        with open(opts.output, "w") as f:
            dump_json( key, f, True )
    return

if __name__ == "__main__":
    main()
