package com.adviser.construct.switchchatter.steps.flavoured;

import java.io.PrintWriter;

import com.adviser.construct.switchchatter.steps.generic.OutputConsumer;
import com.adviser.construct.switchchatter.steps.generic.WaitForStep;

public class WaitForConfigureTerminalPrompt extends WaitForStep {

	public WaitForConfigureTerminalPrompt() {
		super("#");
	}

	@Override
	public int performStep(StringBuffer buffer, PrintWriter pw, OutputConsumer outputConsumer) {
		return getConsumedTill();
	}

}
