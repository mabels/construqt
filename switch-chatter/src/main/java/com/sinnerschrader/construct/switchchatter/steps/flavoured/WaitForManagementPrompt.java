package com.sinnerschrader.construct.switchchatter.steps.flavoured;

import java.io.PrintWriter;

import com.sinnerschrader.construct.switchchatter.steps.generic.WaitForStep;

public class WaitForManagementPrompt extends WaitForStep {

	public WaitForManagementPrompt() {
		super("#");
	}

	@Override
	public int performStep(StringBuffer buffer, PrintWriter pw) {
		return getConsumedTill();
	}

}
