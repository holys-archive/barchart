#!/usr/bin/env python

import csv
import os
import re


def make_csv(csv_file=None, bench_type="redis"):
    """Generate csv data from benchmark.md file"""
    
    if not csv_file:
        csv_file = "data.csv"

    benchmark_data = parse_md(bench_type=bench_type)
    with open(csv_file, 'w') as f:
        writer = csv.writer(f)
        if bench_type == "redis":
            header = ["DB", "GET", "SET", "INCR", "LPUSH", "LPOP", "LPUSH",
                   "LRANGE_100", "LRANGE_300", "LRANGE_500", "LRANGE_600", "MSET"]
            writer.writerow(header)
        elif bench_type == "ledis":

            header = ["DB", "SET", "INCR", "GET", "RPUSH", "LRANGE_10",
                      "LRANGE_50", "LRANGE_100", "LPOP", "HSET", "HGET",
                      "HINCRBY", "HDEL", "ZADD", "ZINCRBY", "ZRANGE",
                      "ZRANGEBYSCORE", "ZREVRANGE", "ZREVRANGEBYSCORE", "ZREM"]
            writer.writerow(header)
        writer.writerows(benchmark_data)


def parse_md(md_file=None, bench_type="redis"):
    if not md_file:
        md_file = "benchmark.md"

    if not os.path.exists(md_file):
        print "No markdown file found."
        return
    rgl = re.compile("```(\w*?)\n(.+?)```", re.S)

    with open(md_file) as f:
        db_list = []
        result = re.findall(rgl, f.read())
        for db in result:
            if len(db[0]) == 0:
                continue

            cmd_list = []
            if db[0].split("_")[1] == bench_type:
                db_type = db[0].split("_")[0]
                if db_type == "goleveldb":
                    db_type = "ledisdb_goleveldb"
                if db_type == "leveldb":
                    db_type = "ledisdb_leveldb"
                if db_type == "rocksdb":
                    db_type = "ledisdb_rocksdb"
                if db_type == "lmdb":
                    db_type = "ledisdb_lmdb"
                cmd_list.append(db_type)

                _cmds = db[1].split("\n")
                cmds = _cmds[:len(_cmds)-1]

                for cmd in cmds:
                    if not cmd:
                        continue
                    value = cmd.split(":")[1].split(" ")[1]
                    cmd_list.append(value)

                db_list.append(cmd_list)
        return db_list

            
if __name__ == "__main__":

    make_csv(csv_file="redis.csv", bench_type="redis")
    make_csv(csv_file="ledis.csv", bench_type="ledis")




