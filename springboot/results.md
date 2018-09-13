# Results

## Setup

Using OpenSSL Binary /usr/local/Cellar/openssl/1.0.2o_2/bin/openssl, override with $OPENSSL_COMMAND
Running benchmarks with OpenSSL version OpenSSL 1.0.2o  27 Mar 2018


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
* No big difference between JRE versions when using OpenSSL
    * Not strange as no real application code is executed

[Spreadsheet loaded in Google Sheets](https://docs.google.com/spreadsheets/d/1J545CueuAOJD5GTCZjQdleUIFxjZPXX06kES5rP4684/edit?usp=sharing)

## Further work

* Add throughput benchmark
    * Small message (10kb)
    * Medium message (512KB)
    * Big message (10MB)
    * Huge message (100MB)
* Try with Finagle/Netty