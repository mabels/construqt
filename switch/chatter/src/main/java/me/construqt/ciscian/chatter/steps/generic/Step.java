package me.construqt.ciscian.chatter.steps.generic;

public class Step {
	public String send() {
		return null;
	}
	public String[] expect() {
		return null;
	}
	public String expectString() {
		if (expect() == null) {
			return "[]";
		}
		StringBuilder sb = new StringBuilder();
		sb.append("[");
		String comma = "";
		for (String t : expect()) {
			sb.append(comma);
			sb.append(t.replaceAll("\\p{C}", "?"));
			comma = ",";
		}
		sb.append("]");
		return sb.toString();
	}
//	int performStep(StringBuilder inputBuffer, Writer terminalWriter, FromDeviceConsumer outputConsumer);
//
//	boolean check(StringBuilder inputBuffer);
//
//	String retrieveResult();
//
//	int getConsumedTill();
}
