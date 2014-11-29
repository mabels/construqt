package me.construqt.ciscian.chatter;

import java.io.Closeable;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import org.apache.commons.io.IOUtils;

import me.construqt.ciscian.chatter.steps.generic.OutputConsumer;

public abstract class SwitchChatter implements Closeable {

	private OutputStream os;

	private InputStream is;

	private OutputConsumer outputConsumer;

	private ExecutorService executorService;

	protected SwitchChatter() {
	}

	public static SwitchChatter create(String flavour, InputStream is,
			OutputStream os, boolean debug) {
		String clazz = "me.construqt.ciscian.chatter.flavour." + flavour
				+ "SwitchChatter";

		try {
			SwitchChatter switchChatter = (SwitchChatter) Class.forName(clazz)
					.newInstance();
			switchChatter.initialize(is, os, debug);
			return switchChatter;
		} catch (ClassNotFoundException e) {
			System.err.println("Flavour " + flavour
					+ " not found (Class not found : " + clazz);
			return null;
		} catch (Exception e) {
			throw new RuntimeException("Cannot create flavour " + flavour, e);
		}
	}

	public PrintWriter getPrintWriter() {
		return new PrintWriter(os, true);
	}

	public void initialize(InputStream is, OutputStream os, boolean debug) {
		this.is = is;
		this.os = os;
		this.executorService = Executors.newSingleThreadExecutor();
		this.outputConsumer = new OutputConsumer(debug, getPrintWriter());
	}

	public void close() {
		IOUtils.closeQuietly(is);
		IOUtils.closeQuietly(os);
		executorService.shutdown();
	}

	public Future<List<String>> start() {
		Callable<List<String>> readingThread = new Callable<List<String>>() {
			@Override
			public List<String> call() {
				try {
					IOUtils.copy(is, outputConsumer);
					return outputConsumer.getResults();
				} catch (IOException e) {
					e.printStackTrace();
				}
				return null;
			}
		};

		return executorService.submit(readingThread);
	}

	public OutputConsumer getOutputConsumer() {
		return outputConsumer;
	}

	protected abstract void enterManagementMode(String username, String password);

	protected abstract void disablePaging();

	protected abstract void applyConfig(String config);

	protected abstract void retrieveConfig();

	protected abstract void exit();

}
