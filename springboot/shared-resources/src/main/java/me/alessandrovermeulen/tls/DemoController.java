package me.alessandrovermeulen.tls;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import java.util.concurrent.CompletableFuture;

@RestController
class DemoController {
    final static String javaVersion = System.getProperty("java.version");
    final static String framework = System.getProperty("framework");

    @GetMapping("/")
    public CompletableFuture<String> index(HttpServletRequest request) {
        return CompletableFuture.completedFuture(javaVersion +" via " + request.getProtocol() + " on " + framework);
    }
}