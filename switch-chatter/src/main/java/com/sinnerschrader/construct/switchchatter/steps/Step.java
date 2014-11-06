package com.sinnerschrader.construct.switchchatter.steps;

public interface Step {
	int performStep(StringBuffer buffer);

	boolean check(StringBuffer buffer);

	String retrieveResult();
}
