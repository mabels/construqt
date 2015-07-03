package me.construqt.ciscian.chatter.flavour;

public abstract class AbstractHpSwitchChatter extends GenericCiscoFlavourSwitchChatter {
	
//	@Override
//	protected void enterManagementMode(final String enablePassword) {
//		getFromDeviceConsumer().addStep(new SwitchStep( //
//				new Expect("Press any key to continue") {
//					public Step[] then() {
//						return new Step[] { new EnterInput("") };
//					}
//				}, new Expect("Username:") {
//					public Step[] then() {
//						return new Step[] { //
//						new EnterInput(username), //
//								new PasswordPrompt(), //
//								new EnterInput(password) };
//					}
//				}, new Expect("Password:") {
//					public Step[] then() {
//						return new Step[] { new EnterInput(password) };
//					}
//				}));
//
//		getFromDeviceConsumer().addStep(new WaitForPrompt());
//	}

//	public void disablePaging() {
//		getFromDeviceConsumer().addStep(new HpDisablePaging());
//		getFromDeviceConsumer().addStep(new WaitForPrompt());
//	}
//
//	public void retrieveConfig() {
//		getFromDeviceConsumer().addStep(new ShowRunningConfig());
//
//		getFromDeviceConsumer().addStep(
//				new WaitForStep(getRunningConfigHeadline()) {
//					@Override
//					public int performStep(StringBuilder input, Writer pw,
//							FromDeviceConsumer outputConsumer) {
//						return getConsumedTill();
//					}
//				});
//
//		getFromDeviceConsumer().addStep(new CollectOutputStep(true, "# "));
//	}
//
//	protected abstract String getRunningConfigHeadline();
//
//	@Override
//	protected void saveRunningConfig() {
//		getFromDeviceConsumer().addStep(new HpWriteMemory());
//	}
//
//	public void exit() {
//		getFromDeviceConsumer().addStep(new Exit());
//		getFromDeviceConsumer().addStep(new WaitForPrompt());
//		getFromDeviceConsumer().addStep(new Exit());
//		getFromDeviceConsumer().addStep(new WaitForStep("y/n"));
//		getFromDeviceConsumer().addStep(new Yes());
//	}
}
