package me.construqt.ciscian.chatter.steps.flavoured;

import java.io.PrintWriter;

import me.construqt.ciscian.chatter.steps.generic.OutputConsumer;
import me.construqt.ciscian.chatter.steps.generic.WaitForRegexStep;

public class AnswerYes extends WaitForRegexStep {

	public AnswerYes() {
		super("y/n");
	}

	@Override
	public int performStep(StringBuffer input, PrintWriter pw,
			OutputConsumer outputConsumer) {
		pw.println("y");
		return getConsumedTill();
	}

}
