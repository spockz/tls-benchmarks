#!/usr/bin/env bash

openSslCommand=${OPENSSL_COMMAND:-"/usr/local/Cellar/openssl/1.0.2o_2/bin/openssl"}

echo "Using OpenSSL Binary $openSslCommand, override with \$OPENSSL_COMMAND"

echo "Running benchmarks with OpenSSL version $(${openSslCommand} version)"

function runBenchmarks() {
    echo "bio , Specific Cipher ECDHE-RSA-AES256-GCM-SHA384"
    ${openSslCommand} s_time -new -connect localhost:8888 -cipher "ECDHE-RSA-AES256-GCM-SHA384" | grep "connections/user sec"
    echo "nio , Specific Cipher ECDHE-RSA-AES256-GCM-SHA384"
    ${openSslCommand} s_time -new -connect localhost:8888 -nbio -cipher "ECDHE-RSA-AES256-GCM-SHA384" | grep "connections/user sec"

    echo "bio, no specific cipher"
    ${openSslCommand} s_time -new -connect localhost:8888 | grep "connections/user sec"
    echo "nio, no specific cipher"
    ${openSslCommand} s_time -new -connect localhost:8888 | grep "connections/user sec"

}

function runBenchmarkStep () {
    server=$1

    echo "Starting server $server"

    $server 1 >$ 2 &
    serverId=$!
    trap "echo \"Killing server\"; kill ${serverId}; exit 1" INT

    echo "Waiting 5s to give application time to start"
    sleep 5s

    echo "Starting Benchmarks"
    runBenchmarks


    kill ${serverId}
    wait "${serverId}"
}

echo "Cleaning and building applications"
#mvn clean package -DskipTests


#echo "Undertow Java 8"
#runBenchmarkStep "/usr/libexec/java_home -v 1.8 --exec java -jar tls-undertow/target/tls-undertow-*.jar"
#
#echo "Undertow Java 10"
#runBenchmarkStep "/usr/libexec/java_home -v 10 --exec java -jar tls-undertow/target/tls-undertow-*.jar"

echo "Tomcat Java 8"
runBenchmarkStep "/usr/libexec/java_home -v 1.8 --exec java -jar tls-tomcat/target/tls-tomcat-*.jar"

echo "Tomcat Java 10"
runBenchmarkStep "/usr/libexec/java_home -v 10 --exec java -jar tls-tomcat/target/tls-tomcat-*.jar"

echo "Tomcat TCNative Java 8"
runBenchmarkStep "/usr/libexec/java_home -v 1.8 --exec java -Djava.library.path=/Users/alessandro/Downloads/tomcat-native-1.2.17-src/native/.libs -jar tls-tomcat/target/tls-tomcat-*.jar"

echo "Tomcat TCNative Java 10"
runBenchmarkStep "/usr/libexec/java_home -v 10 --exec java -Djava.library.path=/Users/alessandro/Downloads/tomcat-native-1.2.17-src/native/.libs -jar tls-tomcat/target/tls-tomcat-*.jar"

