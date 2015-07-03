package me.construqt.ciscian.chatter.connectors;

public interface Connector {

	ConnectResult connect() throws Exception;

	void disconnect() throws Exception;

}
