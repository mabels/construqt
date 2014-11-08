package com.sinnerschrader.construct.switchchatter.steps;

public class CollectOutputStep implements Step {

	private String endMarker;

	private String collected;

	public CollectOutputStep(String endMarker) {
		this.endMarker = endMarker;
	}

	@Override
	public int performStep(StringBuffer buffer) {
		int index = buffer.indexOf(endMarker);
		collected = buffer.substring(0, index);
		return index + 1;
	}

	@Override
	public boolean check(StringBuffer buffer) {
		return buffer.indexOf(endMarker) >= 0;
	}

	@Override
	public String retrieveResult() {
		return collected;
	}

}
