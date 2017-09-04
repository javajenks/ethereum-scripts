#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR"
RECHECK=200
POOL="eth-eu1.nanopool.org:9999"
POOL2="eth-eu2.nanopool.org:9999"
WALLET="7bac9ccfb2cabe0a1ac706ff8e9ce0ad51f1045c"
EMAIL="jj@java2go.com"
WNAME="miner"
#MINERBIN="/mnt/home/bin/ethminer"
MINERBIN="ethminer"

C_SCHEDULE=auto
C_STREAMS=8 #4 #2 #64 #32
C_BLOCKSZ=256 #128
C_GRIDSZ=8192 #16384 #32768 #1024
C_PHASH=8
#--cuda-devices 0 --cuda-schedule auto --cuda-streams 64 --cuda-block-size 128 --cuda-grid-size 16384 --cuda-parallel-hash 8 -M

usage() {
        echo "usage: $0 start|stop|restart <gpu#> " >&2
        exit 1
}

if [[ $# < 2 ]] ; then
        usage
fi

cmd=$1
gpu=$2

# Check if directory exists
if [ ! -d "$ROOT/$WNAME-$gpu/" ]; then
		echo "Error directory $ROOT/$WNAME-$gpu/ doesnt exist"
		exit 1
fi
set GPU_FORCE_64BIT_PTR=0
set GPU_MAX_HEAP_SIZE=100
set GPU_USE_SYNC_OBJECTS=1
set GPU_MAX_ALLOC_PERCENT=100
set GPU_SINGLE_ALLOC_PERCENT=100


startme() {
		if [[ -e $ROOT/$WNAME-$gpu/ethminer.pid ]] ; then
				echo "Error $WNAME-$gpu already running"
				exit 1
		fi
		if [[ -e $ROOT/$WNAME-$gpu/ethminer.log ]]; then
				mv $ROOT/$WNAME-$gpu/ethminer.log $ROOT/$WNAME-$gpu/ethminer.bak
		fi
		#ethminer -G --opencl-device $gpu --farm-recheck 400 --cl-local-work 256 --cl-global-work 16384 -F $POOL/$WALLET/min-$gpu/$EMAIL > $ROOT/$WNAME-$gpu/ethminer.log
		#nohup ethminer -G --opencl-device $gpu --farm-recheck 400 --cl-local-work 256 --cl-global-work 16384 -F $POOL/$WALLET/min-$gpu/$EMAIL > $ROOT/$WNAME-$gpu/ethminer.log &
		nohup $MINERBIN -U --farm-recheck $RECHECK --cuda-devices $gpu \
				--cuda-schedule $C_SCHEDULE --cuda-streams $C_STREAMS --cuda-block-size $C_BLOCKSZ \
				--cuda-grid-size $C_GRIDSZ --cuda-parallel-hash $C_PHASH \
				-S $POOL -FS $POOL2 -O $WALLET.min-$gpu/$EMAIL > $ROOT/$WNAME-$gpu/ethminer.log &
		echo $! > $ROOT/$WNAME-$gpu/ethminer.pid 
}

stopme() {
        if [[ ! -e $ROOT/$WNAME-$gpu/ethminer.pid ]] ; then
                echo "Error $instance was not running"
        else
                echo "Stopping $WNAME-$gpu  .."
                cat $ROOT/$WNAME-$gpu/ethminer.pid | xargs kill
                rm $ROOT/$WNAME-$gpu/ethminer.pid
        fi
}

case "$cmd" in
    start)   startme ;;
    stop)    stopme ;;
    restart) stopme; sleep 1; startme ;;
    *) usage ;;
esac
