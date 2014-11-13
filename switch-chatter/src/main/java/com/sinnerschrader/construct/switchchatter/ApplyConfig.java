package com.sinnerschrader.construct.switchchatter;

import java.io.IOException;
import java.io.StringWriter;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.List;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import org.apache.commons.io.IOUtils;

import com.sinnerschrader.construct.switchchatter.connectors.ConnectResult;
import com.sinnerschrader.construct.switchchatter.connectors.Connector;
import com.sinnerschrader.construct.switchchatter.connectors.ConnectorFactory;

public class ApplyConfig {
	public static void main(String[] args) throws Exception {
		String pass = args[2];
		Connector connector = ConnectorFactory.createConnector(args[1], pass);
		ConnectResult connect = connector.connect();

		StringWriter sw = new StringWriter();
		IOUtils.copy(System.in, sw);

		final SwitchChatter sc = SwitchChatter.create(args[0],
				connect.getInputStream(), connect.getOutputStream(),
				args.length >= 5 && "debug".equals(args[4]));

		// setup steps
		sc.skipSplashScreen();
		sc.enterManagementMode(pass);
		sc.disablePaging();
		sc.applyConfig(sw.toString());
		sc.exit();

		// start procedure
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
			connector.disconnect();
		}
	}
}
