package com.sinnerschrader.construct.switchchatter.steps.generic;

import java.io.PrintWriter;

import org.apache.commons.lang.StringEscapeUtils;

public class WaitForStep implements Step {
	private String waitFor;

	private int consumedTill = -1;

	public WaitForStep(String waitFor) {
		this.waitFor = waitFor;
	}

	public String getWaitForString() {
		return waitFor;
	}

	public int getConsumedTill() {
		return consumedTill;
	}

	@Override
	public boolean check(StringBuffer buffer) {
		int index = buffer.indexOf(getWaitForString());

		if (index >= 0) {
			consumedTill = index + getWaitForString().length();
			return true;
		} else {
			return false;
		}
	}

	@Override
	public String retrieveResult() {
		return null;
	}

	@Override
	public int performStep(StringBuffer input, PrintWriter pw) {
		return getConsumedTill();
	}

	@Override
	public String toString() {
		return getClass().getSimpleName() + "( waiting for "
				+ StringEscapeUtils.escapeJava(waitFor) + ")";
	}

}
