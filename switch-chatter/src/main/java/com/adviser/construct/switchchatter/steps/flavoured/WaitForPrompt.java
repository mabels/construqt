package com.adviser.construct.switchchatter.steps.flavoured;

import java.io.PrintWriter;

import com.adviser.construct.switchchatter.steps.generic.WaitForStep;

public class WaitForPrompt extends WaitForStep {

	public WaitForPrompt() {
		super(">");
	}

	@Override
	public int performStep(StringBuffer buffer, PrintWriter pw) {
		return getConsumedTill();
	}

}
