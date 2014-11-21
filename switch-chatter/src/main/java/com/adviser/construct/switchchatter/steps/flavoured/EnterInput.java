package com.adviser.construct.switchchatter.steps.flavoured;

import java.io.PrintWriter;

import com.adviser.construct.switchchatter.steps.generic.CommandStep;
import com.adviser.construct.switchchatter.steps.generic.OutputConsumer;

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
