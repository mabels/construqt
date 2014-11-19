package com.sinnerschrader.construct.switchchatter.steps.generic;

public abstract class CommandStep implements Step {

	@Override
	public boolean check(StringBuffer buffer) {
		return true;
	}

	@Override
	public String retrieveResult() {
		return null;
	}

}
