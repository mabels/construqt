package com.sinnerschrader.construct.switchchatter;

import java.io.IOException;
import java.net.UnknownHostException;

public class Main {
	public static void main(String[] args) throws UnknownHostException,
			IOException, InterruptedException {
		if (args.length < 3) {
			System.err.println("usage:");
			System.err.println("sc [HOST] [PORT] (read|write) (|debug)");
			System.exit(1);
		}

		if ("write".equals(args[2])) {
			ApplyConfig.main(args);
		} else {
			RetrieveConfig.main(args);
		}
	}
}
