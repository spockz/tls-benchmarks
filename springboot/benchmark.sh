#!/usr/bin/env bash

openSslCommand=${OPENSSL_COMMAND:-"/usr/local/Cellar/openssl@1.1/1.1.1/bin/openssl"}

echo "Using OpenSSL Binary $openSslCommand, override with \$OPENSSL_COMMAND"

echo "Running benchmarks with OpenSSL version $(${openSslCommand} version)"

runID=`date +%Y-%m-%d-%H:%M:%S`
resultsDir=results/${runID}
mkdir ${resultsDir}

function runBenchmarks() {
    openSslCommand=$1
    clientCert=$2
    cipher=$3
    resumption=$4
    page=$5

    cipherPart=""
    if [ ${cipher} != "-" ]; then
        cipherPart="-cipher ${cipher}"
    fi

    clientCertPart=""
    if [ ${clientCert} != "none" ]; then
        clientCertPart="-cert certs/${clientCert}.cer -key certs/${clientCert}.key"
    fi

    wwwArgument=""
    if [ ${page} != "-" ]; then
        wwwArgument="-www /${page}"
    fi

    ${openSslCommand} s_time -time 30 -${resumption} -connect localhost:8888 ${cipherPart} ${clientCertPart} ${wwwArgument}
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
    useExtendedMasterSecret=$9

    libPaths=""

    if [ ${tcNativeVersion} != "-" ]; then
        libPaths="-Djava.library.path=$(pwd)/lib/tcnative/$tcNativeVersion"
    fi

    command="/usr/libexec/java_home -v $jreVersion --exec java ${libPaths} -Djdk.tls.useExtendedMasterSecret=${useExtendedMasterSecret} -Dserver.ssl.key-alias=$serverCertAlias -Dserver.ssl.client-auth=$clientAuth -jar $server/target/$server-*.jar"
    serverLogFile="${resultsDir}/${jreVersion}-$tcNativeVersion-${useExtendedMasterSecret}-$serverCertAlias-$clientAuth-$server.log"
    echo "  Starting server $command"

    $command >${serverLogFile} 2>&1 &
    serverId=$!
    trap "echo \"Killing server\"; kill ${serverId}; exit 1" INT

    echo "  Waiting 4s to give application time to start"
    sleep 4s

    echo "  Starting Benchmarks"

    for openSslCommand in ${openSslCommands[@]}; do
        openSslVersion=$(${openSslCommand} version | cut -d " " -f 2)
        for page in ${pages[@]}; do
            resultFile="${resultsDir}/$server%$jreVersion%${tcNativeVersion}%$clientAuth%$serverCertAlias%$clientCert%$cipher%$resumption%${useExtendedMasterSecret}%${openSslVersion}%${page}"
            errorResultFile="${resultFile}.err"
            runBenchmarks ${openSslCommand} ${clientCert} ${cipher} ${resumption} ${page} > ${resultFile} 2> ${errorResultFile}
        done
    done



    kill ${serverId}
    wait "${serverId}"
}

echo "Cleaning and building applications"
#mvn clean package -DskipTests

executionTime=30

servers=( "tls-tomcat" )
tcNativeVersions=( "1.2.17-openssl-1.0.2" "1.2.17-openssl-1.1.1" "-" )
jreVersions=( "1.8" "10" "11" )
clientAuths=( "need" )
clientCerts=( "none" "client" "client-2048" ) #"client-3072" "client-untrusted-2048" )
serverCertAliases=( "server" "server-2048" )
ciphers=( "-" )
resumptions=( "new" "reuse" )
useExtendedMasterSecret=( "true" "false" )
pages=( "-" "small" "medium" "large" "  huge" )
openSslCommands=( "$openSslCommand" "/usr/local/Cellar/openssl/1.0.2p/bin/openssl" )


for server in ${servers[@]}; do
    for jreVersion in ${jreVersions[@]}; do
        for tcNativeVersion in ${tcNativeVersions[@]}; do

            # Only run benchmarks if native version empty or not empty and server contains tomcat
            if [ ${tcNativeVersion} == "-" ] || [[ $server = *"tomcat"* ]]; then

                for clientAuth in ${clientAuths[@]}; do

                    for serverCertAlias in ${serverCertAliases[@]}; do
                        for clientCert in ${clientCerts[@]}; do
                             for cipher in ${ciphers[@]}; do
                                for resumption in ${resumptions[@]}; do
                                        for enableExtendedMasterSecret in ${useExtendedMasterSecret[@]}; do

                                        echo "Testing Case combination: $server $jreVersion $clientAuth $serverCertAlias $clientCert $cipher $resumption $tcNativeVersion $enableExtendedMasterSecret"

                                        if [ ${clientAuth} == "need" ] && [ ${clientCert} == "none" ]; then
                                            echo "  Skipping test because OpenSSL will fail after the first failed handshake anyway"
                                            continue
                                        fi

                                        if [ ${enableExtendedMasterSecret} == "false" ] && [ ${tcNativeVersion} != "-"} ]; then
                                            echo " Skipping superfluous disabling of extended master secret when running with openssl"
                                            continue
                                        fi

                                        runBenchmarkStep ${server} ${jreVersion} ${clientAuth} ${serverCertAlias} ${clientCert} ${cipher} ${resumption} ${tcNativeVersion} ${enableExtendedMasterSecret}
                                    done
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
