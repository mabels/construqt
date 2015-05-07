package me.construqt.ciscian.chatter.connectors;

import java.net.Socket;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Tcp implements Connector {

	private String host;

	private int port;

	private Socket socket;

	public Tcp(String connectString) {
		Pattern p = Pattern.compile("tcp://(.*):(\\d*)");
		Matcher m = p.matcher(connectString);
		if (m.matches()) {
			this.host = m.group(1);
			this.port = Integer.parseInt(m.group(2));
		} else {
			throw new RuntimeException("Invalid tcp connect string "
					+ connectString);
		}

	}

	public ConnectResult connect() throws Exception {
		socket = new Socket(host, port);
		return new ConnectResult(socket.getInputStream(),
				socket.getOutputStream());
	}

	@Override
	public void disconnect() throws Exception {
		socket.close();
	}

	@Override
	public Type getType() {
	    return Type.TCP;
	}
}
