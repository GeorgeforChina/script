1. Please make sure cli_wallet and get_dev_key are under bin directory
2. Make sure passwd.py and get-chain-id.py are in the directory as they are in github
3. Example:
	cd create-worker
	source create-worker.sh testholly-1 ../wallet/testholly-1-wallet.json "2018-04-18T00:00:00" "2018-04-20T00:00:00" 1 test
4. Make sure keys are imported into wallet
5. How to import key into wallet:
	cd import-key
	source import-key.sh testholly-1 ../wallet/testholly-1-wallet.json ../key/hxy.key
6. Prepare a wallet  
	cp empty-wallet.json testholly-1-wallet.json // create an empty wallet
7. How to create key:
	python gen-key.py -o hxy.key hxy passwd
 
