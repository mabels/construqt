package com.sinnerschrader.construct.switchchatter;

import java.io.IOException;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.List;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import com.sinnerschrader.construct.switchchatter.connectors.ConnectResult;
import com.sinnerschrader.construct.switchchatter.connectors.Connector;
import com.sinnerschrader.construct.switchchatter.connectors.ConnectorFactory;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.Enable;

public class RetrieveConfig {
	public static void main(String[] args) throws Exception {
		String pass = args[2];
		Connector connector = ConnectorFactory.createConnector(args[1], pass);
		ConnectResult connect = connector.connect();

		final SwitchChatter sc = SwitchChatter.create(args[0],
				connect.getInputStream(), connect.getOutputStream(),
				args.length >= 5 && "debug".equals(args[4]));

		// setup steps
		sc.skipSplashScreen();
		sc.enterManagementMode(pass);
		sc.disablePaging();
		sc.retrieveConfig();
		sc.exit();

		// start procedure
		Future<List<String>> result = sc.start();

		try {
			List<String> results = result.get(60, TimeUnit.SECONDS);

			String config = results.get(0);
			System.out.println(config);
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
