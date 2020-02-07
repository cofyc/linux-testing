# kmem cgroup leaking

## How to reproduce SLAB leaking

See reproduce.sh.

You can check that slabs information increases while the test script is
running.

```
watch -n 1 'ls /sys/kernel/slab  | wc -l'
```

I've verified this on following kernels:

- centos7 3.10.0-514.10.2.el7.x86_64

kernel will has following error message:

```
[root@centos7 ~]# grep 'SLUB' /var/log/messages
Feb  7 11:16:40 localhost kernel: SLUB: HWalign=64, Order=0-3, MinObjects=0,
CPUs=6, Nodes=1
Feb  7 05:00:13 centos7 kernel: SLUB: HWalign=64, Order=0-3, MinObjects=0,
CPUs=6, Nodes=1
Feb  7 05:23:41 centos7 kernel: SLUB: Unable to allocate memory on node -1
(gfp=0x8020)
Feb  7 05:23:41 centos7 kernel: SLUB: Unable to allocate memory on node -1
(gfp=0xd0)
Feb  7 05:23:41 centos7 kernel: SLUB: Unable to allocate memory on node -1
(gfp=0xd0)
Feb  7 05:23:43 centos7 kernel: SLUB: Unable to allocate memory on node -1
(gfp=0x8020)
Feb  7 05:23:43 centos7 kernel: SLUB: Unable to allocate memory on node -1
(gfp=0xd0)
...
```

## How to reproduce memory cgroup leaking

```
mkdir /sys/fs/cgroup/memory/test
for i in `seq 1 65535`;do mkdir /sys/fs/cgroup/memory/test/test-${i}; done
```

Enable kmem accounting in a cgroup, and remove it later.

```
for n in 1 -1; do
    echo $n > /sys/fs/cgroup/memory/test/test-1/memory.kmem.limit_in_bytes
done
echo $$ > /sys/fs/cgroup/memory/test/test-1/cgroup.procs
echo $$ > /sys/fs/cgroup/memory/cgroup.procs
rmdir /sys/fs/cgroup/memory/test/test-1
```

Cannot create new cgroup even if the number of mem cgroups does not reach the
limit.

```
mkdir /sys/fs/cgroup/memory/test/test-1
```

See
https://github.com/kubernetes/kubernetes/issues/61937#issuecomment-377512486.

I've verified this on following kernels:

- centos7 3.10.0-1062.12.1.el7.x86_64

In this kernel version, no slab leaking but still has memory cgroup leaking
problem.

Solutions:

- Upgrade kernel to 4.x
- Add `cgroup.memory=nokmem` kernel parameter to disable this completely.

This issue might be fixed in centos 7.8 (3.10.0-1075.el7), but I didn't verify
it.

## References

- https://pingcap.com/blog/try-to-fix-two-linux-kernel-bugs-while-testing-tidb-operator-in-k8s/
- https://github.com/opencontainers/runc/issues/1725
- https://bugzilla.redhat.com/show_bug.cgi?id=1507149
