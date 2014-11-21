package com.adviser.construct.switchchatter.steps.generic;

import java.io.PrintWriter;

public interface Step {
	int performStep(StringBuffer inputBuffer, PrintWriter terminalWriter, OutputConsumer outputConsumer);

	boolean check(StringBuffer inputBuffer);

	String retrieveResult();
}
