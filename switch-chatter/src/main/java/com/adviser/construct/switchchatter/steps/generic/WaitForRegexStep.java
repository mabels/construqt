package com.adviser.construct.switchchatter.steps.generic;

import java.io.PrintWriter;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang.StringEscapeUtils;

public class WaitForRegexStep implements Step {
	private Pattern waitForPattern;

	private int consumedTill = -1;

	public WaitForRegexStep(String waitForPattern) {
		this.waitForPattern = Pattern.compile(waitForPattern);
	}

	public String getWaitForPattern() {
		return waitForPattern.toString();
	}

	public int getConsumedTill() {
		return consumedTill;
	}

	@Override
	public boolean check(StringBuffer buffer) {
		Matcher m = waitForPattern.matcher(buffer);
		if (m.find()) {
			consumedTill = m.end();
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
	public int performStep(StringBuffer input, PrintWriter pw,
			OutputConsumer outputConsumer) {
		return getConsumedTill();
	}

	@Override
	public String toString() {
		return getClass().getSimpleName() + "( waiting for "
				+ StringEscapeUtils.escapeJava(getWaitForPattern()) + ")";
	}

}
