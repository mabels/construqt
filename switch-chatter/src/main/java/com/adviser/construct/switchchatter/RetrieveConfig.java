package com.adviser.construct.switchchatter;

import java.util.List;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import com.adviser.construct.switchchatter.connectors.ConnectResult;
import com.adviser.construct.switchchatter.connectors.Connector;
import com.adviser.construct.switchchatter.connectors.ConnectorFactory;

public class RetrieveConfig {
	public static void main(String[] args) throws Exception {
		String user = args[2];
		String pass = args[3];
		Connector connector = ConnectorFactory.createConnector(args[1], user,
				pass);
		ConnectResult connect = connector.connect();

		final SwitchChatter sc = SwitchChatter.create(args[0],
				connect.getInputStream(), connect.getOutputStream(),
				args.length >= 6 && "debug".equals(args[5]));

		// setup steps
		sc.enterManagementMode(user, pass);
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
