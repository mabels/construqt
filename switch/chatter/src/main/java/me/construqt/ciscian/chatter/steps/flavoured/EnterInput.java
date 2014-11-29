package me.construqt.ciscian.chatter.steps.flavoured;

import java.io.PrintWriter;

import me.construqt.ciscian.chatter.steps.generic.CommandStep;
import me.construqt.ciscian.chatter.steps.generic.OutputConsumer;

public class EnterInput extends CommandStep {

	private String input;

	public EnterInput(String input) {
		this.input = input;
	}

	@Override
	public int performStep(StringBuffer inputBuffer, PrintWriter terminalWriter, OutputConsumer outputConsumer) {
		terminalWriter.println(input);
		return 0;
	}

}
