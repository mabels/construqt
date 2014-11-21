package com.adviser.construct.switchchatter.steps.flavoured;

import java.io.PrintWriter;

import com.adviser.construct.switchchatter.steps.generic.CommandStep;

public class Yes extends CommandStep {
	@Override
	public int performStep(StringBuffer input, PrintWriter pw) {
		pw.println("y");
		return 0;
	}

}
