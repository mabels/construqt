package com.sinnerschrader.construct.switchchatter.steps.flavoured;

import java.io.PrintWriter;

import com.sinnerschrader.construct.switchchatter.steps.generic.CommandStep;

public class Exit extends CommandStep {
	@Override
	public int performStep(StringBuffer input, PrintWriter pw) {
		pw.println("exit");
		return 0;
	}

}
