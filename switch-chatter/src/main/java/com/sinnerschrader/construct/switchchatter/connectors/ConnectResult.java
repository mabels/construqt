package com.sinnerschrader.construct.switchchatter.connectors;

import java.io.InputStream;
import java.io.OutputStream;

public class ConnectResult {
	private InputStream inputStream;

	private OutputStream outputStream;

	public ConnectResult(InputStream inputStream, OutputStream outputStream) {
		this.inputStream = inputStream;
		this.outputStream = outputStream;
	}

	public InputStream getInputStream() {
		return inputStream;
	}

	public void setInputStream(InputStream inputStream) {
		this.inputStream = inputStream;
	}

	public OutputStream getOutputStream() {
		return outputStream;
	}

	public void setOutputStream(OutputStream outputStream) {
		this.outputStream = outputStream;
	}
}
