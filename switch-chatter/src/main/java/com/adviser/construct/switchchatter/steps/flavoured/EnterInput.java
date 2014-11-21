package com.adviser.construct.switchchatter.steps.flavoured;

import java.io.PrintWriter;

import com.adviser.construct.switchchatter.steps.generic.CommandStep;

public class EnterInput extends CommandStep {

	private String input;

	public EnterInput(String input) {
		this.input = input;
	}

	@Override
	public int performStep(StringBuffer inputBuffer, PrintWriter terminalWriter) {
		terminalWriter.println(input);
		return 0;
	}

}
