package me.construqt.ciscian.chatter.steps.generic;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

import org.apache.commons.io.output.NullWriter;

public class OutputConsumer extends java.io.FilterWriter {

	private PrintWriter consoleWriter;

	private LinkedList<Step> plan = new LinkedList<Step>();

	List<String> results = new ArrayList<String>();

	private PrintWriter printWriter;

	private boolean showProgress;

	public OutputConsumer(boolean debugOnStdErr, PrintWriter printWriter,
			boolean showProgress) {
		super(new StringWriter());
		consoleWriter = debugOnStdErr ? new PrintWriter(System.err, true)
				: new PrintWriter(new NullWriter(), true);
		this.printWriter = printWriter;
		this.showProgress = showProgress;
	}

	public void addStep(Step step) {
		this.plan.add(step);
		checkExpected();
	}

	@Override
	public void write(int c) throws IOException {
		super.write(c);
		consoleWriter.write(sanitize(c));
		consoleWriter.flush();
		checkExpected();
	}

	private int sanitize(int c) {
		if (c == 27) {
			c = '+';
		}
		return c;
	}

	private char[] sanitize(char[] c) {
		char[] s = new char[c.length];
		for (int i = 0; i < s.length; i++) {
			s[i] = (char) sanitize(c[i]);
		}
		return s;
	}

	private String sanitize(String c) {
		return String.copyValueOf(sanitize(c.toCharArray()));
	}

	private void checkExpected() {
		if (showProgress) {
			System.err.print(".");
		}
		
		consoleWriter.print("\n[check expected called]");
		consoleWriter.flush();
		try {
			out.flush();
		} catch (IOException e) {
			throw new RuntimeException("An error occured while flushing.", e);
		}
		StringBuffer buffer = ((StringWriter) out).getBuffer();
		Step step = getCurrentStep();
		consoleWriter.print("\n[check expected " + step + "]");
		consoleWriter.flush();
		if (step != null) {
			boolean succeeded = step.check(buffer);

			if (succeeded) {
				// remove current step
				plan.poll();

				// call listener
				int consumedTill = step.performStep(buffer, printWriter, this);

				// retrieve result
				String result = step.retrieveResult();
				if (result != null) {
					results.add(result);
				}

				if (consumedTill > 0) {
					// clear buffer
					buffer.delete(0, consumedTill);
				}

				checkExpected();
			}
		}
	}

	public void insertAfterCurrentStep(Step[] steps) {
		plan.addAll(0, Arrays.asList(steps));
	}

	public Step getCurrentStep() {
		return plan.peek();
	}

	@Override
	public void write(char[] cbuf, int off, int len) throws IOException {
		super.write(cbuf, off, len);
		consoleWriter.write(sanitize(cbuf), off, len);
		consoleWriter.flush();
		checkExpected();
	}

	@Override
	public void write(String str, int off, int len) throws IOException {
		super.write(str, off, len);
		consoleWriter.write(sanitize(str), off, len);
		consoleWriter.flush();
		checkExpected();
	}

	public List<String> getResults() {
		return results;
	}

}
