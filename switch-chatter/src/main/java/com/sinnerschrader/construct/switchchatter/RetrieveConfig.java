package com.sinnerschrader.construct.switchchatter;

import java.io.IOException;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.List;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

public class RetrieveConfig {
	public static void main(String[] args) throws UnknownHostException,
			IOException, InterruptedException {
		Socket socket = new Socket(args[0], Integer.parseInt(args[1]));

		final SwitchChatter sc = new SwitchChatter(socket.getInputStream(),
				socket.getOutputStream());

		// setup steps
		sc.createOutputConsumer(args.length >= 4 && "debug".equals(args[3]));
		sc.skipSplashScreen();
		sc.setupTerminal();
		sc.retrieveConfig();
		sc.exit();

		// start procedure
		Future<List<String>> result = sc.start();

		try {
			List<String> results = result.get(3, TimeUnit.SECONDS);

			String config = results.get(0);
			System.out.println(config);
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
