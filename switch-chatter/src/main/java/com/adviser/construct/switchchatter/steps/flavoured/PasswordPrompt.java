package com.adviser.construct.switchchatter.steps.flavoured;

import java.io.PrintWriter;

import com.adviser.construct.switchchatter.steps.generic.WaitForStep;

public class PasswordPrompt extends WaitForStep {

	public PasswordPrompt() {
		super("Password:");
	}

	@Override
	public int performStep(StringBuffer inputBuffer, PrintWriter terminalWriter) {
		return getConsumedTill();
	}

}
