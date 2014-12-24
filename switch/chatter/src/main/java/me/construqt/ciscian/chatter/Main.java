package me.construqt.ciscian.chatter;

public class Main {

	static class CLIOptions {
		String flavour;
		String connect;
		String user;
		String password;
		String mode;
		boolean debug;
		boolean persist;

		public static CLIOptions build(String args[]) {
			if (args.length < 5) {
				String message = "usage:\nsc <flavour> <connect> <user> <password> (read|write) [--persist] [--debug]";
				throw new IllegalArgumentException(message);
			}

			CLIOptions options = new CLIOptions();
			options.flavour = args[0];
			options.connect = args[1];
			options.user = args[2];
			options.password = args[3];
			options.mode = args[4];

			// scan optional flags
			for (String arg : args) {
				switch (arg) {
				case "--debug":
					options.debug = true;
					break;
				case "--persist":
					options.persist = true;
					break;
				}
			}

			return options;
		}
	}

	public static void main(String[] args) throws Exception {

		try {
			CLIOptions options = CLIOptions.build(args);
			if ("write".equals(options.mode)) {
				ApplyConfig.apply(options);
			} else {
				RetrieveConfig.retrieve(options);
			}
		} catch (RuntimeException e) {
			System.err.println(e.getMessage());
			System.exit(1);
		}
	}

}
