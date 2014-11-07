package com.sinnerschrader.construct.switchchatter;

import java.io.IOException;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.List;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

public class ApplyConfig {
	public static void main(String[] args) throws UnknownHostException,
			IOException, InterruptedException {
		Socket socket = new Socket("172.16.252.252", 23);

		final SwitchChatter sc = new SwitchChatter(socket.getInputStream(),
				socket.getOutputStream());

		Future<List<String>> result = sc.createOutputConsumerAndFutureResult();
		sc.skipSplashScreen();
		sc.setupTerminal();
		sc.applyConfig("vlan 5000000\nvlan 1000000\nexit\n");
		sc.exit();

		try {
			List<String> results = result.get(3, TimeUnit.SECONDS);
			int errors = 0;
			for (String line : results) {
				int errorMessage = line.indexOf("Invalid");
				if (errorMessage >= 0) {
					System.err.println(line.substring(errorMessage,
							line.indexOf("\n")));
				}
				errors++;
			}
			if (errors > 0) {
				System.exit(1);
			}
		} catch (Exception e) {
			System.err.println("fatal error occured:");
			e.printStackTrace(System.err);
			System.exit(2);
		} finally {
			sc.close();
			socket.close();
		}
	}
}
