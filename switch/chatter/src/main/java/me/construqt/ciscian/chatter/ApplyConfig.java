package me.construqt.ciscian.chatter;

import java.io.StringWriter;
import java.util.List;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import org.apache.commons.io.IOUtils;

import me.construqt.ciscian.chatter.connectors.ConnectResult;
import me.construqt.ciscian.chatter.connectors.Connector;
import me.construqt.ciscian.chatter.connectors.ConnectorFactory;

public class ApplyConfig {
	public static void main(String[] args) throws Exception {
		String user = args[2];
		String pass = args[3];
		Connector connector = ConnectorFactory.createConnector(args[1], user,
				pass);
		ConnectResult connect = connector.connect();

		StringWriter sw = new StringWriter();
		IOUtils.copy(System.in, sw);

		final SwitchChatter sc = SwitchChatter.create(args[0],
				connect.getInputStream(), connect.getOutputStream(),
				args.length >= 6 && "debug".equals(args[5]));

		// setup steps
		sc.enterManagementMode(user, pass);
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
					System.err.println(line);
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
