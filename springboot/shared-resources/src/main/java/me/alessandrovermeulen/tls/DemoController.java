package me.alessandrovermeulen.tls;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import java.util.Random;
import java.util.concurrent.CompletableFuture;

@RestController
class DemoController {
    private final static String javaVersion = System.getProperty("java.version");
    private final static String framework = System.getProperty("framework");


    private final static Random random = new Random();

    private final static byte[] small = new byte[10*1024];
    private final static byte[] medium = new byte[512*1024];
    private final static byte[] large = new byte[10*1024*1024];
    private final static byte[] huge = new byte[100*1024*1024];

    {
        random.nextBytes(small);
        random.nextBytes(medium);
        random.nextBytes(large);
        random.nextBytes(huge);
    }

    @GetMapping("/")
    public CompletableFuture<String> index(HttpServletRequest request) {
        return CompletableFuture.completedFuture(javaVersion +" via " + request.getProtocol() + " on " + framework);
    }

    @GetMapping("/small")
    public CompletableFuture<byte[]> small() {
        return CompletableFuture.completedFuture(small);
    }

    @GetMapping("/medium")
    public CompletableFuture<byte[]> medium() {
        return CompletableFuture.completedFuture(medium);
    }

    @GetMapping("/large")
    public CompletableFuture<byte[]> large() {
        return CompletableFuture.completedFuture(large);
    }

    @GetMapping("/huge")
    public CompletableFuture<byte[]> huge() {
        return CompletableFuture.completedFuture(huge);
    }
}