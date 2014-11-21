package com.adviser.construct.switchchatter.steps.flavoured;

import java.io.PrintWriter;

import com.adviser.construct.switchchatter.steps.generic.CommandStep;
import com.adviser.construct.switchchatter.steps.generic.OutputConsumer;

public class ShowRunningConfig extends CommandStep {
	@Override
	public int performStep(StringBuffer input, PrintWriter pw, OutputConsumer outputConsumer) {
		pw.println("show running-config");
		return 0;
	}
}
