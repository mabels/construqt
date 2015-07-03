package me.construqt.ciscian.chatter;

public class Util {
	public static String replaceAllTerminalControlCharacters(String str) {
		return str.replaceAll("[^\\w\\S\\d]", "?");
	}
	public static String replaceAllTerminalControlCharacters(String[] strs) {
		StringBuilder sb = new StringBuilder();
		String comma = "";
		for (String str : strs) {
			sb.append(comma);
			comma = ",";
			sb.append(replaceAllTerminalControlCharacters(str));
		}
		return sb.toString();
	}
}
