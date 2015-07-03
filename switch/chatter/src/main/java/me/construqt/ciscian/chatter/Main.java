package me.construqt.ciscian.chatter;

import me.construqt.ciscian.chatter.flavour.DellN40xxSwitchChatter;
import me.construqt.ciscian.chatter.flavour.DlinkDgs15xxSwitchChatter;
import me.construqt.ciscian.chatter.flavour.Hp2510gSwitchChatter;
import me.construqt.ciscian.chatter.flavour.Hp2530gSwitchChatter;

import java.net.InetAddress;
import java.net.Socket;

public class Main {

	static class CLIOptions {
		String flavour;
		String connect;
		String user;
		String password;
		String enablePassword;
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
			options.enablePassword = args[3];
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

	public static void registerFlavours() {

		SwitchFactory.registerSwitchChatterFactory(new SwitchFactory.Factory() {
			@Override
			public String getName() {
				return "DellN40xx";
			}

			@Override
			public SwitchActions getInstance() {
				return new DellN40xxSwitchChatter();
			}
		});

		SwitchFactory.registerSwitchChatterFactory(new SwitchFactory.Factory() {
			@Override
			public String getName() {
				return "DlinkDgs15xx";
			}

			@Override
			public SwitchActions getInstance() {
				return new DlinkDgs15xxSwitchChatter();
			}
		});

		SwitchFactory.registerSwitchChatterFactory(new SwitchFactory.Factory() {
			@Override
			public String getName() {
				return "Hp2510g";
			}

			@Override
			public SwitchActions getInstance() {
				return new Hp2510gSwitchChatter();
			}
		});

		SwitchFactory.registerSwitchChatterFactory(new SwitchFactory.Factory() {
			@Override
			public String getName() {
				return "Hp2530g";
			}

			@Override
			public SwitchActions getInstance() {
				return new Hp2530gSwitchChatter();
			}
		});

	}

	public static void main(String[] args) throws Exception {

		registerFlavours();
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
