# Apache Spark

## Quick Start

https://spark.apache.org/docs/latest/quick-start.html

`spark-shell` for interactive queries, `spark-submit` to submit job JARs.

Build Scala project with `sbt package`, then:

```bash
spark-submit \
--class "SparkStart" \
--master local[4] \
target/scala-2.11/spark-starter-project_2.11-1.0.jar
```

## Versioning

It sucks. Scala binaries aren't backwards-compatible, [gotta use specific Scala version with Spark](https://stackoverflow.com/a/43883531/854694):

> For the Scala API, Spark 2.4.4 uses Scala 2.12. You will need to use a compatible Scala version (2.12.x).

But... check the actual Scala version in the Spark web UI (Environment > Runtime Information > Scala Version). Even though I'm on Spark 2.4.4, it's using Scala 2.11.12.

Update `build.sbt` to use the same major Scala version as Spark:
```
scalaVersion := "2.11.12"
```

I think this means you have to rebuild every application when you upgrade to a new Spark version, ugh.