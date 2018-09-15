# Results

## Setup

Using OpenSSL Binary /usr/local/Cellar/openssl@1.1/1.1.1/bin/openssl, override with $OPENSSL_COMMAND
Running benchmarks with client OpenSSL version OpenSSL 1.1.1  11 Sep 2018

TCNative 1.2.17 compiled with OpenSSL: 1.0.2o_2 and APR 1.6.3.

### Hardware
MacOS 10.12.6
3,6 GHz 6-Core Intel Xeon E5
32 GB 2133 MHz DDR4

## Analysis
Results of the first run with just tomcat8 are in report/outcome-run1.csv. Some analysis, in order of 'discovery':

* TLS Resumption when using TCNative offers a huge gain
    * mutualTLS goes from ±173 connections/s to ±400 connections/s when using 2048 keys.
* Client key size doesn't appear to be as significant as the server key size in terms of impact in connections/s
* TLS Resumption doesn't appear to work (or enabled) out of the box when using Spring Boot + JSSE + Tomcat.
    * Disabling jdk.tls.useExtendedMasterSecret does indeed enable re-use when using OpenSSL
* No big difference between JRE versions when using OpenSSL
    * Not strange as no real application code is executed
* No big difference between `want` and `need` when client certificate is provided.

[Spreadsheet loaded in Google Sheets](https://docs.google.com/spreadsheets/d/1J545CueuAOJD5GTCZjQdleUIFxjZPXX06kES5rP4684/edit?usp=sharing)

## Further work

* Add throughput benchmark
    * Small message (10kb)
    * Medium message (512KB)
    * Big message (10MB)
    * Huge message (100MB)
* Try with Finagle/Netty
* Include extendedMasterSecret in the test parameters and test with OpenSSL 1.1.0+ which has support for Extended Master Secret.


## Reproducing
* Build and Copy TCNative
    * Download source
    * Install APR
        * `brew install apr`
    * Install OpenSSL
        * `brew install openssl openssl@1.1`
    * ```
        ./configure --with-ssl=/usr/local/Cellar/openssl@1.1/1.1.1 --with-apr=/usr/local/Cellar/apr/1.6.3/bin --with-java-home=/Library/Java/JavaVirtualMachines/jdk1.8.0_172.jdk/Contents/Home
        make
        copy files to lib/tcnative/1.2.17-openssl-1.1.1
        make clean
        ./configure --with-ssl=/usr/local/Cellar/openssl/1.0.2o_2 --with-apr=/usr/local/Cellar/apr/1.6.3/bin --with-java-home=/Library/Java/JavaVirtualMachines/jdk1.8.0_172.jdk/Contents/Home
        make
        copy files to lib/tcnative/1.2.17-openssl-1.0.2
      ```
* in the `springboot` directory run `./benchmark.sh`
* To get to files in report:
    * grep -lR "connections in 31 real" . | xargs tail -1 | pbcopy
    * paste into favorite editor
    * Replace `==> ./(.*) <==\n(\d+).*\d+.*(\d+).*\n` with `$1,$2,$3`
    * Replace `%` with `,`
    * Add to the top `server,jreVersion,tcNativeVersion,clientAuth,serverCert,clientCert,cipher,resumption,enabledExtendedMasterSecret,page,connections/30s,bytes/connection`