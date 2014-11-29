package me.construqt.ciscian.chatter.steps.flavoured;

import java.io.PrintWriter;

import me.construqt.ciscian.chatter.steps.generic.CommandStep;
import me.construqt.ciscian.chatter.steps.generic.OutputConsumer;

public class Exit extends CommandStep {
	@Override
	public int performStep(StringBuffer input, PrintWriter pw, OutputConsumer outputConsumer) {
		pw.println("exit");
		return 0;
	}

}
