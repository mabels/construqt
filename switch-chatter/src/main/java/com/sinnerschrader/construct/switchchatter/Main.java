package com.sinnerschrader.construct.switchchatter;


public class Main {
	public static void main(String[] args) throws Exception {
		if (args.length < 4) {
			System.err.println("usage:");
			System.err
					.println("sc [FLAVOUR] [CONNECT_STRING] [PASSWORD] (read|write) (|debug)");
			System.exit(1);
		}

		if ("write".equals(args[3])) {
			ApplyConfig.main(args);
		} else {
			RetrieveConfig.main(args);
		}
	}
}
