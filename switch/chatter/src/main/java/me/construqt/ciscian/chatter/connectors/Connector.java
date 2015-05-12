package me.construqt.ciscian.chatter.connectors;

public interface Connector {

    public enum Type {
        SSH, TCP
    }

	ConnectResult connect() throws Exception;

	void disconnect() throws Exception;

	Type getType();
}
