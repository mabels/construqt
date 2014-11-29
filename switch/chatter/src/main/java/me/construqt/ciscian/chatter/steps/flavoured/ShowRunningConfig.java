package me.construqt.ciscian.chatter.steps.flavoured;

import java.io.PrintWriter;

import me.construqt.ciscian.chatter.steps.generic.CommandStep;
import me.construqt.ciscian.chatter.steps.generic.OutputConsumer;

public class ShowRunningConfig extends CommandStep {
	@Override
	public int performStep(StringBuffer input, PrintWriter pw, OutputConsumer outputConsumer) {
		pw.println("show running-config");
		return 0;
	}
}
