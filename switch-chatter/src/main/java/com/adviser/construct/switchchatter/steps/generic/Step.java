package com.adviser.construct.switchchatter.steps.generic;

import java.io.PrintWriter;

public interface Step {
	int performStep(StringBuffer inputBuffer, PrintWriter terminalWriter);

	boolean check(StringBuffer inputBuffer);

	String retrieveResult();
}
