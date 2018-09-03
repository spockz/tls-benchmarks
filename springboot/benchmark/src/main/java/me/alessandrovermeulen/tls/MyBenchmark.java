/*
 * Copyright (c) 2014, Oracle America, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *  * Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 *  * Neither the name of Oracle nor the names of its contributors may be used
 *    to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package me.alessandrovermeulen.tls;

import com.twitter.finagle.Http;
import com.twitter.finagle.ListeningServer;
import com.twitter.finagle.Service;
import com.twitter.finagle.http.Request;
import com.twitter.finagle.http.Response;
import com.twitter.finagle.ssl.*;
import com.twitter.finagle.ssl.client.SslClientConfiguration;
import com.twitter.finagle.ssl.server.SslServerConfiguration;
import com.twitter.util.Await;
import com.twitter.util.Future;
import com.twitter.util.TimeoutException;
import org.openjdk.jmh.annotations.*;
import scala.Option;

import java.io.File;
import java.util.Collections;

public class MyBenchmark {

    @State(Scope.Benchmark)
    public static class MyState {
        final SslServerConfiguration sslServerConfiguration = new SslServerConfiguration(
                KeyCredentialsConfig.certAndKey(new File("./client.crt"), new File("./client.key")),
                ClientAuthConfig.NEEDED,
                TrustCredentialsConfig.certCollection(new File("./client.crt")),
                CipherSuitesConfig.UNSPECIFIED,
                ProtocolsConfig.enabled(Collections.singletonList("TLSv1.2")),
                ApplicationProtocolsConfig.UNSPECIFIED
        );

        ListeningServer server = null;

        @Setup(Level.Trial)
        public void setup() {
            final Service<Request, Response> id = Service.mk(req -> Future.value(Response.apply()));
            server = Http.server().withTransport().tls(sslServerConfiguration).serve(":9999", id);
        }

        @TearDown(Level.Trial)
        public void doTearDown() throws TimeoutException, InterruptedException {
            Await.ready(server.close());
        }

        final SslClientConfiguration sslClientConfiguration = new SslClientConfiguration(Option.empty(),
                KeyCredentialsConfig.certAndKey(new File("./client.crt"), new File("./client.key")),
//                KeyCredentialsConfig.UNSPECIFIED,
                TrustCredentialsConfig.INSECURE,
                CipherSuitesConfig.UNSPECIFIED,
                ProtocolsConfig.enabled(Collections.singletonList("TLSv1.2")),
                ApplicationProtocolsConfig.UNSPECIFIED);

        final Http.Client client = Http.client().withHttp2().withTransport().tls(sslClientConfiguration);
    }

    @Benchmark
    @BenchmarkMode(Mode.Throughput)
    public void testSpringBootServer(MyState state) throws Exception {
        final Service<Request, Response> connection = state.client.newService("127.0.0.1:8888");
        Await.result(connection.apply(Request.apply("/")));
        Await.ready(connection.close());
    }


//    @Benchmark
//    @BenchmarkMode(Mode.Throughput)
//    public void testFinagleServer(MyState state) throws Exception {
//        final Service<Request, Response> connection = state.client.newService("127.0.0.1:9999");
//        Await.result(connection.apply(Request.apply("/")));
//        Await.ready(connection.close());
//    }
}
