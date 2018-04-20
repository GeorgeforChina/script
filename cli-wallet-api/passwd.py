import os
import getpass

def get_pass():
                if "CYBEX_PASSWD" in os.environ:
                    pwd = os.environ["CYBEX_PASSWD"]
                else:
                    pwd = getpass.getpass("Current Wallet Passphrase:")
                return pwd
