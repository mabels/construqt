package me.construqt.ciscian.chatter.flavour;

import me.construqt.ciscian.chatter.SwitchActions;
//import me.construqt.ciscian.chatter.steps.generic.Writer;
import me.construqt.ciscian.chatter.SwitchSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class GenericCiscoFlavourSwitchChatter implements SwitchActions {

	private static final Logger LOG = LoggerFactory.getLogger(GenericCiscoFlavourSwitchChatter.class);

	protected SwitchSession session;

	public void setSession(SwitchSession session) {
		this.session = session;
	}

	public void applyConfig(String config) {
//		getFromDeviceConsumer().addStep(new ConfigureTerminal());
//		getFromDeviceConsumer().addStep(new WaitForPrompt());
//
//		String[] lines = config.split("\\n");
//		for (int i = 0; i < lines.length; i++) {
//			final String line = lines[i];
//			getFromDeviceConsumer().addStep(new CommandStep() {
//				@Override
//				public int performStep(StringBuilder input, Writer pw, FromDeviceConsumer outputConsumer) {
//					pw.println(line);
//					LOG.debug("Applying config: " + line);
//					return 0;
//				}
//			});
//			getFromDeviceConsumer().addStep(
//					new CollectOutputStep(false, "#"));
//		}
//
//		getFromDeviceConsumer().addStep(new Exit());
	}

	public void login(final String username, final String password) throws Exception {
		session.match(
				new SwitchSession.Expect(new SwitchSession.CaseAction() {
					@Override
					public boolean action(SwitchSession sc) throws Exception {
						sc.learnPrompt();
						sc.send("\n");
						return false;
					}
				}, session.getEnablePrompt(), session.getUserPrompt()),
				new SwitchSession.Expect(new SwitchSession.CaseAction() {
					@Override
					public boolean action(SwitchSession sc) throws Exception {
						sc.sendln(username);
						return false;
					}
				}, "Username:"),
				new SwitchSession.Expect(new SwitchSession.CaseAction() {
					@Override
					public boolean action(SwitchSession sc) throws Exception {
						sc.sendln(password);
						return false;
					}
				}, "Password:")
		);
	}

	@Override
	public void enterManagementMode(final String enablePassword) throws Exception {
		session.match(
				new SwitchSession.Expect(new SwitchSession.CaseAction() {
					@Override
					public boolean action(SwitchSession sc) throws Exception {
						session.sendln("");
						return false;
					}
				}, session.getEnablePrompt()),
				new SwitchSession.Expect(new SwitchSession.CaseAction() {
					@Override
					public boolean action(SwitchSession sc) throws Exception {
						sc.sendln("enable");
						sc.expect("Password:");
						sc.sendln(enablePassword);
						return false;
					}
				}, session.getUserPrompt())
		);
	}

	public void exit() throws Exception {
		session.match(
				new SwitchSession.Expect(new SwitchSession.CaseAction() {
					@Override
					public boolean action(SwitchSession sc) throws Exception {
						sc.sendln("exit");
						return false;
					}
				}, session.getEnablePrompt()),
				new SwitchSession.Expect(new SwitchSession.CaseAction() {
					@Override
					public boolean action(SwitchSession sc) throws Exception {
						sc.sendln("exit");
						return false;
					}
				}, session.getUserPrompt())
		);
	}

	public StringBuilder retrieveConfig() throws Exception {
		session.match(
				new SwitchSession.Expect(new SwitchSession.CaseAction() {
					@Override
					public boolean action(SwitchSession sc) throws Exception {
						sc.sendln("terminal length 0");
						return false;
					}
				}, session.getEnablePrompt()));
		session.match(
				new SwitchSession.Expect(new SwitchSession.CaseAction() {
					@Override
					public boolean action(SwitchSession sc) throws Exception {
						sc.sendln("show running-config");
						return false;
					}
				}, session.getEnablePrompt()));
			return null;
	}



	public void saveRunningConfig() throws Exception {
		session.match(
				new SwitchSession.Expect(new SwitchSession.CaseAction() {
					@Override
					public boolean action(SwitchSession sc) throws Exception {
						sc.sendln("write memory");
						return false;
					}
				}, session.getEnablePrompt()));
 	}

}
