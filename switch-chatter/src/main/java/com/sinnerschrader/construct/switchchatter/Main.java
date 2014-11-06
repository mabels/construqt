package com.sinnerschrader.construct.switchchatter;

import java.io.IOException;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.List;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

public class Main {
	public static void main(String[] args) throws UnknownHostException,
			IOException, InterruptedException {
		Socket socket = new Socket("172.16.252.252", 23);

		final SwitchChatter sc = new SwitchChatter(socket.getInputStream(),
				socket.getOutputStream());

		Future<List<String>> result = sc.createOutputConsumerAndFutureResult();
		sc.skipSplashScreen();
		sc.retrieveConfig();
		sc.exit();

		try {
			List<String> results = result.get(3, TimeUnit.SECONDS);

			String config = results.get(0);
			System.out.println(config);
		} catch (Exception e) {
			System.err.println("fatal error occured:");
			e.printStackTrace(System.err);
		} finally {
			sc.close();
			socket.close();
		}
	}
}
