package me.construqt.ciscian.chatter.steps.generic;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang.StringEscapeUtils;

public class WaitForRegexStep extends Step {
	private String[] waitForPatterns;


	public WaitForRegexStep(String ...waitForPatterns) {
		this.waitForPatterns = waitForPatterns;
	}

	@Override
	public String[] expect() {
		return waitForPatterns;
	}

}
