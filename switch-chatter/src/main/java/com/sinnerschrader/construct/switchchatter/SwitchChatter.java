package com.sinnerschrader.construct.switchchatter;

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

import com.sinnerschrader.construct.switchchatter.steps.CollectOutputStep;
import com.sinnerschrader.construct.switchchatter.steps.CommandStep;
import com.sinnerschrader.construct.switchchatter.steps.OutputConsumer;
import com.sinnerschrader.construct.switchchatter.steps.WaitForStep;

public class SwitchChatter implements Closeable {

	private final OutputStream os;

	private final InputStream is;

	private OutputConsumer outputConsumer;

	private ExecutorService executorService;

	public SwitchChatter(InputStream is, OutputStream os) {
		this.is = is;
		this.os = os;
		this.executorService = Executors.newSingleThreadExecutor();
	}

	public void close() {
		IOUtils.closeQuietly(is);
		IOUtils.closeQuietly(os);
		executorService.shutdown();
	}

	public Future<List<String>> createOutputConsumerAndFutureResult() {
		this.outputConsumer = new OutputConsumer();

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

	public void skipSplashScreen() {
		PrintWriter pw = new PrintWriter(os, true);

		outputConsumer.addStep(new WaitForStep("Press any key to continue") {
			@Override
			public int performStep(StringBuffer input) {
				pw.println();
				return getConsumedTill();
			}
		});

		outputConsumer.addStep(new WaitForStep("#") {
			@Override
			public int performStep(StringBuffer input) {
				return getConsumedTill();
			}
		});
	}

	public void retrieveConfig() {
		PrintWriter pw = new PrintWriter(os, true);

		outputConsumer.addStep(new CommandStep() {
			@Override
			public int performStep(StringBuffer input) {
				pw.println("show running-config");
				return 0;
			}
		});

		outputConsumer.addStep(new WaitForStep("Running configuration:\n\r") {
			@Override
			public int performStep(StringBuffer input) {
				return getConsumedTill();
			}
		});

		outputConsumer.addStep(new CollectOutputStep("" + (char) 27));
	}

	public void exit() {
		PrintWriter pw = new PrintWriter(os, true);

		outputConsumer.addStep(new CommandStep() {
			@Override
			public int performStep(StringBuffer input) {
				pw.println("exit");
				pw.println("exit");
				pw.println("y");
				return 0;
			}
		});
	}

}
