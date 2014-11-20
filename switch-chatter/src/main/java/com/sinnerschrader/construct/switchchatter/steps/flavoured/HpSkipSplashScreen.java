package com.sinnerschrader.construct.switchchatter.steps.flavoured;

import java.io.PrintWriter;

import com.sinnerschrader.construct.switchchatter.steps.generic.WaitForStep;

public class HpSkipSplashScreen extends WaitForStep {

	public HpSkipSplashScreen() {
		super("Press any key to continue");
	}

	@Override
	public int performStep(StringBuffer buffer, PrintWriter pw) {
		pw.println();
		return getConsumedTill();
	}

}
