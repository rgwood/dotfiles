# pgbench

pgbench runs a variation of [TPC-B](http://www.tpc.org/tpcb/default.asp), which is mostly intended to stress CPU, memory, disk/IO.

[Useful "pgbench basics" article](https://blog.codeship.com/tuning-postgresql-with-pgbench/).

Baseline from my Ubuntu VM, with pg defaults (128MB shared_buffers), 2 processors, 2GB RAM:

```
pgbench -c 10 -j 2 -t 10000 benchmarks
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 4
query mode: simple
number of clients: 10
number of threads: 2
number of transactions per client: 10000
number of transactions actually processed: 100000/100000
latency average = 5.363 ms
tps = 1864.521083 (including connections establishing)
tps = 1864.626262 (excluding connections establishing)
```

If I bump shared_buffers to 512MB we get much better performance:

```
latency average = 4.397 ms
tps = 2274.089265 (including connections establishing)
tps = 2274.284918 (excluding connections establishing)
```