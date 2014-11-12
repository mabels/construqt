package com.sinnerschrader.construct.switchchatter;

import java.io.IOException;
import java.io.StringWriter;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.List;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import org.apache.commons.io.IOUtils;

public class ApplyConfig {
	public static void main(String[] args) throws UnknownHostException,
			IOException, InterruptedException {
		Socket socket = new Socket(args[0], Integer.parseInt(args[1]));

		StringWriter sw = new StringWriter();
		IOUtils.copy(System.in, sw);

		final SwitchChatter sc = new SwitchChatter(socket.getInputStream(),
				socket.getOutputStream());

		//setup steps
		sc.createOutputConsumer(args.length >= 4 && "debug".equals(args[3]));
		sc.skipSplashScreen();
		sc.setupTerminal();
		sc.applyConfig(sw.toString());
		sc.exit();
		
		//start procedure
		Future<List<String>> result = sc.start();

		try {
			List<String> results = result.get(60, TimeUnit.SECONDS);
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
