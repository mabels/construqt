package me.construqt.ciscian.chatter;

import java.util.List;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import me.construqt.ciscian.chatter.Main.CLIOptions;
import me.construqt.ciscian.chatter.connectors.ConnectResult;
import me.construqt.ciscian.chatter.connectors.Connector;
import me.construqt.ciscian.chatter.connectors.ConnectorFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class RetrieveConfig {

	private static final Logger LOG = LoggerFactory.getLogger(RetrieveConfig.class);

	public static void retrieve(CLIOptions options) throws Exception {
		// String user = args[2];
		// String pass = args[3];
		Connector connector = ConnectorFactory.createConnector(options.connect,
				options.user, options.password);
		ConnectResult connect = connector.connect();

		final SwitchSession sc = SwitchFactory.create(options.flavour,
				connect.getInputStream(), connect.getOutputStream(),
				options.debug, true);

		// setup steps
		sc.login(options.user, options.password);
		sc.enterManagementMode(options.enablePassword);
		//sc.disablePaging();
		sc.retrieveConfig();
		sc.exit();
		sc.close();

//		// start procedure
//		Future<List<String>> result = sc.start();
//
//		try {
//			List<String> results = result.get(60, TimeUnit.SECONDS);
//
//			String config = results.get(0);
//			LOG.debug(config);
//		} catch (Exception e) {
//			LOG.error("fatal error occured:", e);
//			System.exit(2);
//		} finally {
//			sc.close();
//			connector.disconnect();
//		}
	}
}
