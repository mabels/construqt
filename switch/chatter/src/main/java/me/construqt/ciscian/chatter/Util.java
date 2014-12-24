package me.construqt.ciscian.chatter;

public class Util {
	public static String replaceAllTerminalControlCharacters(String str) {
		return str.replaceAll("\u001b\\[(\\d+;?)+\\w", "");
	}
}
