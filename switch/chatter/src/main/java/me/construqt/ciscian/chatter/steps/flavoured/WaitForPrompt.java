package me.construqt.ciscian.chatter.steps.flavoured;

import java.io.PrintWriter;

import me.construqt.ciscian.chatter.steps.generic.OutputConsumer;
import me.construqt.ciscian.chatter.steps.generic.WaitForRegexStep;

public class WaitForPrompt extends WaitForRegexStep {

	public WaitForPrompt() {
		super("(\\r|\\n|;)[^\\r\\n]+(>|#)");
	}

	@Override
	public int performStep(StringBuffer buffer, PrintWriter pw,
			OutputConsumer outputConsumer) {
		return getConsumedTill();
	}

	public static void main(String[] args) {
		StringBuffer buffer = new StringBuffer();
		buffer.append("\n\r\n\rhp-test-1#\n\r");		
		System.out.println(new WaitForPrompt().check(buffer));
	}
}
