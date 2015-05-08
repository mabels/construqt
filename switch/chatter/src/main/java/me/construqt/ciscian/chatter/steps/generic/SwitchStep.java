package me.construqt.ciscian.chatter.steps.generic;

import java.io.PrintWriter;
import java.util.Arrays;

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

	/** {@inheritDoc} */
	@Override
	public String toString() {
		final StringBuilder builder = new StringBuilder();
		builder.append("SwitchStep [cases=");
		builder.append(Arrays.toString(this.cases));
		builder.append("]");
		return builder.toString();
	}
}
