package com.adviser.construct.switchchatter;


public class Main {
	public static void main(String[] args) throws Exception {
		if (args.length < 5) {
			System.err.println("usage:");
			System.err
					.println("sc [FLAVOUR] [CONNECT_STRING] [USER] [PASSWORD] (read|write) (|debug)");
			System.exit(1);
		}

		if ("write".equals(args[4])) {
			ApplyConfig.main(args);
		} else {
			RetrieveConfig.main(args);
		}
	}
}
