package com.sinnerschrader.construct.switchchatter.steps.flavoured;

import java.io.PrintWriter;

import com.sinnerschrader.construct.switchchatter.steps.generic.WaitForStep;

public class DlinkPasswordPrompt extends WaitForStep {

	public DlinkPasswordPrompt() {
		super("Password:");
	}

	@Override
	public int performStep(StringBuffer inputBuffer, PrintWriter terminalWriter) {
		return getConsumedTill();
	}

}
