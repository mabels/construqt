package com.adviser.construct.switchchatter.connectors;

public class ConnectorFactory {
	public static Connector createConnector(String connectString, String pass) {
		if (connectString.startsWith("ssh:")) {
			return new Ssh(connectString, pass);
		} else if (connectString.startsWith("tcp:")) {
			return new Tcp(connectString, pass);
		} else {
			throw new RuntimeException(
					"Cannot find connector for connect string " + connectString);
		}
	}
}
