package me.construqt.ciscian.chatter.steps.flavoured;

import java.io.PrintWriter;

import me.construqt.ciscian.chatter.steps.generic.OutputConsumer;
import me.construqt.ciscian.chatter.steps.generic.WaitForStep;

public class PasswordPrompt extends WaitForStep {

	public PasswordPrompt() {
		super("Password:");
	}

	@Override
	public int performStep(StringBuffer inputBuffer, PrintWriter terminalWriter, OutputConsumer outputConsumer) {
		return getConsumedTill();
	}

}
