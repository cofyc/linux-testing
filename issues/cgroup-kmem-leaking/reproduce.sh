#!/bin/bash

function clean_recursively() {
    for subd in $(find "$1" -mindepth 1 -maxdepth 1 -type d); do
        clean_recursively $subd
    done
    for p in $(cat $1/cgroup.procs); do
        echo $p > /sys/fs/cgroup/memory/cgroup.procs
    done
    rmdir $1
}


echo "info: cleaning test directories"
if test -d /sys/fs/cgroup/memory/test; then
    cd /sys/fs/cgroup/memory/test
    for d in $(ls -d test*); do
        clean_recursively $d
    done
fi

mkdir /sys/fs/cgroup/memory/test

for i in $(seq 1 100000); do
    echo "info: creating test$i"
    mkdir test$i
    if [ $? -ne 0 ]; then
       break
    fi
    pushd test$i
    # By default, the limit is the MAX but disable We need to set and reset its
    # value to the MAX again to enable it but keep the limit the max.
    # https://github.com/kolyshkin/runc/blob/6a2c15596845f6ff5182e2022f38a65e5dfa88eb/libcontainer/cgroups/fs/kmem.go#L19-L30
    for n in 1 -1; do
       echo $n > memory.kmem.limit_in_bytes
    done
    #sleep 10 >/dev/null 2>&1 &
    echo $$ > cgroup.procs
    popd
    echo $$ > /sys/fs/cgroup/memory/cgroup.procs
    #rmdir test$i
done
