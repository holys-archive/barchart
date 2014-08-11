#!/bin/bash 

# Remember to close binlog output
config="./etc/ledis.conf"
benchmark="benchmark.md"

leveldb="leveldb"
goleveldb="goleveldb"
rocksdb="rocksdb"
lmdb="lmdb"
boltdb="boltdb"
hyperleveldb="hyperleveldb"
redis="redis"
ssdb="ssdb"
ledis="ledis"
ledis_server="ledis-server"

home=$(pwd)

# Set up your environment here
ledis_path="/Users/holys/work/src/github.com/siddontang/ledisdb"
ssdb_path="/Users/holys/work/ssdb-master"
redis_path="/Users/holys/work/redis-2.8.13"



function kill_process()
{
    pid=$(ps axu|grep -v grep |grep $1 | awk '{print $2}')
    kill  $pid > /dev/null 2&>1
}



function ledis_bench()
{   
    cd "$ledis_path"
    source ./dev.sh

    rm -rf ./var

    nohup ledis-server -config=$config -db_name=$1 >nohup.out 2&>1 &

    pid=$(ps axu|grep -v grep |grep ledis-server | awk '{print $2}')

    if [ "$4" == "$redis" ];then
        echo "\n\`\`\`$1_$redis" 
        redis-benchmark -p $2 -n $3 -t set,incr,get,lpush,lpop,lrange,mset -q
        echo "\`\`\`"
    elif [ "$4" == "$ledis" ];then
        echo "\n\`\`\`$1_$ledis"
        ledis-benchmark -port=$2 -n=$3 
        echo "\`\`\`"
    fi

    kill_process $ledis_server
    cd $home
    sleep 1

}

function redis_bench() 
{
    cd "$redis_path"

    nohup ./src/redis-server redis.conf &

    #FIXME: weird! If remove the following line, benchmark not work correctly.
    pid=$(ps axu|grep -v grep |grep redis-server | awk '{print $2}')

    if [ "$3" == "$redis" ]; then
        echo "\n\`\`\`redis_redis"
        redis-benchmark -p $1 -n $2 -t set,incr,get,lpush,lpop,lrange,mset -q 
        echo "\`\`\`"
    elif [ "$3" == "$ledis" ];then
        echo "\n\`\`\`redis_ledis"
        ledis-benchmark -port=$1 -n=$2 
        echo "\`\`\`"
    fi
    
    kill_process redis-server 
    cd $home
    sleep 1
}

function ssdb_bench()
{
    cd $ssdb_path
    rm -rf ./var
    mkdir -p ./var

    nohup ./ssdb-server ssdb.conf  &


    #FIXME: weird! If remove the following line, benchmark not work correctly.
    pid=$(ps axu|grep -v grep |grep ssdb-server | awk '{print $2}')

    if [ "$3" == "$redis" ]; then
        echo "\n\`\`\`ssdb_redis"
        redis-benchmark -p $1 -n $2 -t set,incr,get,lpush,lpop,lrange,mset -q 
        echo "\`\`\`"
    elif [ "$3" == "$ledis" ];then
        echo "\n\`\`\`ssdb_ledis"
        ledis-benchmark -port=$1 -n=$2 
        echo "\`\`\`"
    fi
    kill_process ssdb-server
    cd $home
    sleep 1
}

function bench_all()

{
    ledis_bench $goleveldb 6380 $1 $redis
    ledis_bench $leveldb 6380 $1 $redis
    ledis_bench $rocksdb 6380 $1 $redis
    ledis_bench $lmdb 6380 $1 $redis
    ledis_bench $boltdb 6380 $1  $redis
    redis_bench 6379  $1 $redis 
    ssdb_bench 8888 $1 $redis

    ledis_bench $goleveldb 6380 $2  $ledis
    ledis_bench $leveldb 6380 $2 $ledis
    ledis_bench $rocksdb 6380 $2 $ledis
    ledis_bench $lmdb 6380 $2 $ledis
    ledis_bench $boltdb 6380  $2 $ledis
    redis_bench 6379 $2 $ledis
    ssdb_bench 8888 $2 $ledis

    ledis_bench $hyperleveldb 6380 $1 $redis
    ledis_bench $hyperleveldb 6380 $1 $ledis

}

function main()
{
    if [ -f "$benchmark" ];then
      rm $benchmark
    fi
    #change your benchmark max requests number here
    # bench_all $1 $2
    # $1 for redis-benchmark tool
    # $2 for ledis-benchmark tool, greater than 1000 is must
    bench_all 50000 3000
}

main



#FIXME: have to copy & paste the output to `benchmark.md` file.
# output redirect not work for me :(

