package me.construqt.ciscian.chatter.steps.generic;

import java.io.PrintWriter;

import me.construqt.ciscian.chatter.Util;

import org.apache.commons.lang.StringEscapeUtils;

public class CollectOutputStep implements Step {

	private String[] endMarkers;

	private String collected;

	private boolean rejectLastLine;

	public CollectOutputStep(boolean rejectLastLine, String... endMarkers) {
		this.rejectLastLine = rejectLastLine;
		this.endMarkers = endMarkers;
	}

	@Override
	public int performStep(StringBuffer buffer, PrintWriter pw,
			OutputConsumer outputConsumer) {
		int index = findLastIndex(buffer);
		collected = buffer.substring(0, index);
		if (rejectLastLine) {
			collected = collected.substring(0, collected.lastIndexOf("\n"));
		}
		collected = Util.replaceAllTerminalControlCharacters(collected);
		return index + 1;
	}

	@Override
	public boolean check(StringBuffer buffer) {
		return findLastIndex(buffer) >= 0;
	}

	@Override
	public String retrieveResult() {
		return collected.replaceAll("\r", "");
	}

	public int findLastIndex(StringBuffer buffer) {
		int fromIndex = 0;
		int foundIndex = 0;
		for (String endMarker : endMarkers) {
			foundIndex = buffer.indexOf(endMarker, fromIndex);
			if (foundIndex >= 0) {
				fromIndex = foundIndex + endMarker.length();
			} else {
				break;
			}
		}
		return foundIndex;
	}

	@Override
	public String toString() {
		return getClass().getSimpleName()
				+ "( waiting for "
				+ StringEscapeUtils
						.escapeJava(endMarkers[endMarkers.length - 1]) + ")";
	}

}
