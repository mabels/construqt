package me.construqt.ciscian.chatter.connectors;

import java.io.InputStream;
import java.io.OutputStream;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.jcraft.jsch.Channel;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.UserInfo;

public class Ssh implements Connector {

	private Session session;

	private Channel channel;

	private String host;

	private int port;

	private String user;

	private String pass;

	public Ssh(String connectString, String user, String pass) {
		Pattern p = Pattern.compile("ssh://(.*):(\\d*)");
		Matcher m = p.matcher(connectString);
		if (m.matches()) {
			this.host = m.group(1);
			this.port = Integer.parseInt(m.group(2));
			this.user = user;
			this.pass = pass;
		} else {
			throw new RuntimeException("Invalid ssh connect string "
					+ connectString);
		}
	}

	public ConnectResult connect() throws Exception {
		JSch jsch = new JSch();
		this.session = jsch.getSession(user, host, port);

		// username and password will be given via UserInfo interface.
		UserInfo ui = new UserInfo() {

			@Override
			public void showMessage(String message) {
				// System.err.println(message);
			}

			@Override
			public boolean promptYesNo(String message) {
				// System.err.println(message);
				return true;
			}

			@Override
			public boolean promptPassword(String arg0) {
				return true;
			}

			@Override
			public boolean promptPassphrase(String message) {
				// System.err.println(message);
				return true;
			}

			@Override
			public String getPassword() {
				return pass;
			}

			@Override
			public String getPassphrase() {
				throw new RuntimeException("Not implemented.");
			}
		};

		session.setUserInfo(ui);
		session.connect();

		this.channel = session.openChannel("shell");
		InputStream in = channel.getInputStream();
		OutputStream os = channel.getOutputStream();
		channel.connect();

		return new ConnectResult(in, os);
	}

	public void disconnect() {
		channel.disconnect();
		session.disconnect();
	}

}
