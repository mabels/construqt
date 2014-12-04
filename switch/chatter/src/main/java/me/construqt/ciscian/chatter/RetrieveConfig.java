package me.construqt.ciscian.chatter;

import java.util.List;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import me.construqt.ciscian.chatter.Main.CLIOptions;
import me.construqt.ciscian.chatter.connectors.ConnectResult;
import me.construqt.ciscian.chatter.connectors.Connector;
import me.construqt.ciscian.chatter.connectors.ConnectorFactory;

public class RetrieveConfig {
	public static void retrieve(CLIOptions options) throws Exception {
		// String user = args[2];
		// String pass = args[3];
		Connector connector = ConnectorFactory.createConnector(options.connect,
				options.user, options.password);
		ConnectResult connect = connector.connect();

		final SwitchChatter sc = SwitchChatter.create(options.flavour,
				connect.getInputStream(), connect.getOutputStream(),
				options.debug);

		// setup steps
		sc.enterManagementMode(options.user, options.password);
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
