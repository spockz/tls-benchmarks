package me.alessandrovermeulen.tls;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class TlsTomcatApplication {
	public static void main(String[] args) {
		SpringApplication.run(TlsTomcatApplication.class, args);
	}

}
