package me.construqt.ciscian.chatter.connectors;

import java.net.Socket;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Tcp implements Connector {

    private String host;

    private int port;

    private Socket socket;


    public Tcp(final String connectString) {
        final Pattern p = Pattern.compile("tcp://(.*):(\\d*)");
        final Matcher m = p.matcher(connectString);
        if (m.matches()) {
            this.host = m.group(1);
            this.port = Integer.parseInt(m.group(2));
        } else {
            throw new RuntimeException("Invalid tcp connect string " + connectString);
        }

    }

    @Override
    public ConnectResult connect() throws Exception {
        this.socket = new Socket(this.host, this.port);
        return new ConnectResult(this.socket.getInputStream(), this.socket.getOutputStream());
    }

    @Override
    public void disconnect() throws Exception {
        this.socket.close();
    }

    @Override
    public Type getType() {
        return Type.TCP;
    }

}
