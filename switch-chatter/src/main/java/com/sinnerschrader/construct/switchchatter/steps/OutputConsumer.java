package com.sinnerschrader.construct.switchchatter.steps;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;

import org.apache.commons.io.output.NullWriter;

public class OutputConsumer extends java.io.FilterWriter {

	PrintWriter consoleWriter = new PrintWriter(new NullWriter());
	//PrintWriter consoleWriter = new PrintWriter(System.out);

	private Queue<Step> plan = new LinkedList<Step>();

	List<String> results = new ArrayList<String>();

	public OutputConsumer() {
		super(new StringWriter());
	}

	public void addStep(Step step) {
		this.plan.add(step);
	}

	@Override
	public void write(int c) throws IOException {
		super.write(c);
		consoleWriter.write(c);
		consoleWriter.flush();
		checkExpected();
	}

	private void checkExpected() {
		StringBuffer buffer = ((StringWriter) out).getBuffer();
		Step step = getCurrentStep();
		if (step != null) {
			boolean succeeded = step.check(buffer);

			if (succeeded) {
				// call listener
				int consumedTill = step.performStep(buffer);

				// retrieve result
				String result = step.retrieveResult();
				if (result != null) {
					results.add(result);
				}

				// remove step
				plan.poll();

				if (consumedTill > 0) {
					// clear buffer
					buffer.delete(0, consumedTill);
				}

				checkExpected();
			}
		}
	}

	public Step getCurrentStep() {
		return plan.peek();
	}

	@Override
	public void write(char[] cbuf, int off, int len) throws IOException {
		super.write(cbuf, off, len);
		consoleWriter.write(cbuf, off, len);
		consoleWriter.flush();
		checkExpected();
	}

	@Override
	public void write(String str, int off, int len) throws IOException {
		super.write(str, off, len);
		consoleWriter.write(str, off, len);
		consoleWriter.flush();
		checkExpected();
	}

	public List<String> getResults() {
		return results;
	}

}
