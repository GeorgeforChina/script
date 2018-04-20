
if [ $# -lt 6 ];
then
   echo "usage: create-worker <owner_account> <wallet> <begin_date> <end_date> <daily_pay> <name>"
   return 0
fi

owner_account=$1
wallet=$2
begin_date=$3
end_date=$4
daily_pay=$5
name=$6


chain_id=$(python /mnt/bts/get-chain-id.py)



#/mnt/bts/bin/cli_wallet -r 0.0.0.0:8091 -s ws://127.0.0.1:8090 --chain-id ${chain_id}  -w  "${wallet}"  -d & 
../bin/cli_wallet -r 0.0.0.0:8091 -s ws://127.0.0.1:8090 --chain-id ${chain_id}  -w  "${wallet}"  -d & 

echo $! > cli_wallet.pid

sleep 2
#python /mnt/bts/unlock-wallet.py -p 8091 123456


export CYBEX_PASSWD="123456"
python create-worker.py  ${owner_account} ${begin_date} ${end_date} ${daily_pay} ${name} 

 
pid=$(cat cli_wallet.pid)

kill -9 ${pid}
rm -rf cli_wallet.pid
 
