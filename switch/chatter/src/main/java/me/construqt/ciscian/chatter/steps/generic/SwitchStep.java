package me.construqt.ciscian.chatter.steps.generic;

import java.io.PrintWriter;

public class SwitchStep implements Step {
	private Case[] cases;

	public SwitchStep(Case... cases) {
		this.cases = cases;
	}

	@Override
	public int performStep(StringBuffer inputBuffer,
			PrintWriter terminalWriter, OutputConsumer outputConsumer) {
		outputConsumer
				.insertAfterCurrentStep(findCaseMatch(inputBuffer).then());
		return 0;
	}

	@Override
	public boolean check(StringBuffer inputBuffer) {
		return findCaseMatch(inputBuffer) != null;

	}

	private Case findCaseMatch(StringBuffer buffer) {
		for (Case scase : cases) {
			if (scase.match(buffer)) {
				return scase;
			}
		}
		return null;
	}

	@Override
	public String retrieveResult() {
		return null;
	}
}
