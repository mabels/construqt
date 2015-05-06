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


    public Ssh(final String connectString, final String user, final String pass) {
        final Pattern p = Pattern.compile("ssh://(.*):(\\d*)");
        final Matcher m = p.matcher(connectString);
        if (m.matches()) {
            this.host = m.group(1);
            this.port = Integer.parseInt(m.group(2));
            this.user = user;
            this.pass = pass;
        } else {
            throw new RuntimeException("Invalid ssh connect string " + connectString);
        }
    }

    @Override
    public ConnectResult connect() throws Exception {
        final JSch jsch = new JSch();
        this.session = jsch.getSession(this.user, this.host, this.port);

        // username and password will be given via UserInfo interface.
        final UserInfo ui = new UserInfo() {

            @Override
            public void showMessage(final String message) {
                // System.err.println(message);
            }

            @Override
            public boolean promptYesNo(final String message) {
                // System.err.println(message);
                return true;
            }

            @Override
            public boolean promptPassword(final String arg0) {
                return true;
            }

            @Override
            public boolean promptPassphrase(final String message) {
                // System.err.println(message);
                return true;
            }

            @Override
            public String getPassword() {
                return Ssh.this.pass;
            }

            @Override
            public String getPassphrase() {
                throw new RuntimeException("Not implemented.");
            }
        };

        this.session.setUserInfo(ui);
        this.session.connect();

        this.channel = this.session.openChannel("shell");
        final InputStream in = this.channel.getInputStream();
        final OutputStream os = this.channel.getOutputStream();
        this.channel.connect();

        return new ConnectResult(in, os);
    }

    @Override
    public void disconnect() {
        this.channel.disconnect();
        this.session.disconnect();
    }

    @Override
    public Type getType() {
        return Type.SSH;
    }
}
