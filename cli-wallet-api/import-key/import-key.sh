
if [ $# -lt 3 ];
then
   echo "usage: import-key <account> <wallet> <key> [<port>]"
   return 0
fi


if [ $# -gt 3 ];
then
port=$4
else
port="8090"
fi

account=$1
wallet=$2
key=$3




chain_id=$(python /mnt/bts/get-chain-id.py -p ${port})



/mnt/bts/bin/cli_wallet -r 0.0.0.0:8091 -s ws://127.0.0.1:8090 --chain-id ${chain_id}  -w  "${wallet}"  -d & 

echo $! > cli_wallet.pid

sleep 2
#python /data/bts/unlock-wallet.py -p 8091 123456

python import-key.py  ${account} ${key} ${wallet}

 
pid=$(cat cli_wallet.pid)

kill -9 ${pid}
rm -rf cli_wallet.pid
 
