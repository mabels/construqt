package me.construqt.ciscian.chatter.steps.flavoured;

import java.io.PrintWriter;

import me.construqt.ciscian.chatter.steps.generic.CommandStep;
import me.construqt.ciscian.chatter.steps.generic.OutputConsumer;

public class Yes extends CommandStep {
	@Override
	public int performStep(StringBuffer input, PrintWriter pw, OutputConsumer outputConsumer) {
		pw.println("y");
		return 0;
	}

}
