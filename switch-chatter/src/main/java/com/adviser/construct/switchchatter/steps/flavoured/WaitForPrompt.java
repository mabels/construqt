package com.adviser.construct.switchchatter.steps.flavoured;

import java.io.PrintWriter;

import com.adviser.construct.switchchatter.steps.generic.OutputConsumer;
import com.adviser.construct.switchchatter.steps.generic.WaitForRegexStep;

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
