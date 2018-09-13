#!/usr/bin/env bash

openSslCommand=${OPENSSL_COMMAND:-"/usr/local/Cellar/openssl/1.0.2o_2/bin/openssl"}

echo "Using OpenSSL Binary $openSslCommand, override with \$OPENSSL_COMMAND"

echo "Running benchmarks with OpenSSL version $(${openSslCommand} version)"

function runBenchmarks() {
    clientCert=$1
    cipher=$2
    resumption=$3


    cipherPart=""
    if [ ${cipher} != "-" ]; then
        cipherPart="-cipher ${cipher}"
    fi

    clientCertPart=""
    if [ ${clientCert} != "none" ]; then
        clientCertPart="-cert certs/${clientCert}.cer -key certs/${clientCert}.key"
    fi

    ${openSslCommand} s_time -time 30 -${resumption} -connect localhost:8888 ${cipherPart} ${clientCertPart}
}

function runBenchmarkStep () {
    server=$1
    jreVersion=$2
    clientAuth=$3
    serverCertAlias=$4
    clientCert=$5
    cipher=$6
    resumption=$7
    tcNativeVersion=$8

    libPaths=""

    if [ ${tcNativeVersion} != "-" ]; then
        libPaths="-Djava.library.path=/Users/alessandro/Downloads/tomcat-native-$tcNativeVersion-src/native/.libs"
    fi

    command="/usr/libexec/java_home -v $jreVersion --exec java ${libPaths} -Dserver.ssl.key-alias=$serverCertAlias -Dserver.ssl.client-auth=$clientAuth -jar $server/target/$server-*.jar"

    echo "Starting server $command"

    $command 1 >$ 2 &
    serverId=$!
    trap "echo \"Killing server\"; kill ${serverId}; exit 1" INT

    echo "Waiting 4s to give application time to start"
    sleep 4s

    echo "Starting Benchmarks"
    resultFile="results/$server%$jreVersion%${tcNativeVersion}%$clientAuth%$serverCertAlias%$clientCert%$cipher%$resumption.txt"
    errorResultFile="results/$server%$jreVersion%${tcNativeVersion}%$clientAuth%$serverCertAlias%$clientCert%$cipher%$resumption-error.txt"
    runBenchmarks ${clientCert} ${cipher} ${resumption} > ${resultFile} 2> ${errorResultFile}


    kill ${serverId}
    wait "${serverId}"
}

echo "Cleaning and building applications"
#mvn clean package -DskipTests

executionTime=30

servers=( "tls-tomcat" "tls-tomcat-9" "tls-undertow" )
tcNativeVersions=( "-" "1.2.17" )
jreVersions=( "1.8" "10" "11" )
clientAuths=( "need" "want" )
clientCerts=( "none" "client" "client-2048" "client-3072" "client-untrusted-2048" )
serverCertAliases=( "server" "server-2048" )
ciphers=( "-" )
resumptions=( "new" "reuse" )


for server in ${servers[@]}; do
    for jreVersion in ${jreVersions[@]}; do
        for tcNativeVersion in ${tcNativeVersions[@]}; do

            # Only run benchmarks if native version empty or not empty and server contains tomcat
            if [ $tcNativeVersion == "-" ] || [[ $server = *"tomcat"* ]]; then

                for clientAuth in ${clientAuths[@]}; do

                    for serverCertAlias in ${serverCertAliases[@]}; do
                        for clientCert in ${clientCerts[@]}; do
                             for cipher in ${ciphers[@]}; do
                                for resumption in ${resumptions[@]}; do
                                    runBenchmarkStep ${server} ${jreVersion} ${clientAuth} ${serverCertAlias} ${clientCert} ${cipher} ${resumption} ${tcNativeVersion}
                                done
                             done
                        done
                    done
                done
            else
                echo "Skipping superfluous benchmark $server + $jreVersion + TCNative: $tcNativeVersion"
            fi

        done
    done
done

#echo "Undertow Java 8"
#runBenchmarkStep "/usr/libexec/java_home -v 1.8 --exec java -jar tls-undertow/target/tls-undertow-*.jar"
#
#echo "Undertow Java 10"
#runBenchmarkStep "/usr/libexec/java_home -v 10 --exec java -jar tls-undertow/target/tls-undertow-*.jar"

#echo "Tomcat 8.5.34 Java 8"
#runBenchmarkStep "/usr/libexec/java_home -v 1.8 --exec java -jar tls-tomcat/target/tls-tomcat-*.jar"
#
#echo "Tomcat 8.5.34 Java 10"
#runBenchmarkStep "/usr/libexec/java_home -v 10 --exec java -jar tls-tomcat/target/tls-tomcat-*.jar"
#
#echo "Tomcat 8.5.34 TCNative Java 8"
#runBenchmarkStep "/usr/libexec/java_home -v 1.8 --exec java -Djava.library.path=/Users/alessandro/Downloads/tomcat-native-1.2.17-src/native/.libs -jar tls-tomcat/target/tls-tomcat-*.jar"
#
#echo "Tomcat 8.5.34 TCNative Java 10"
#runBenchmarkStep "/usr/libexec/java_home -v 10 --exec java -Djava.library.path=/Users/alessandro/Downloads/tomcat-native-1.2.17-src/native/.libs -jar tls-tomcat/target/tls-tomcat-*.jar"
#
