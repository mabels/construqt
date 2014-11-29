package me.construqt.ciscian.chatter.connectors;

public class ConnectorFactory {
	public static Connector createConnector(String connectString, String user,
			String pass) {
		if (connectString.startsWith("ssh:")) {
			return new Ssh(connectString, user, pass);
		} else if (connectString.startsWith("tcp:")) {
			return new Tcp(connectString);
		} else {
			throw new RuntimeException(
					"Cannot find connector for connect string " + connectString);
		}
	}
}
