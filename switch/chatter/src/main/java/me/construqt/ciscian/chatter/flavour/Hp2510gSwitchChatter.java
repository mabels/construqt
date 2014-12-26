package me.construqt.ciscian.chatter.flavour;

import java.io.PrintWriter;

import me.construqt.ciscian.chatter.steps.flavoured.Enable;
import me.construqt.ciscian.chatter.steps.flavoured.EnterInput;
import me.construqt.ciscian.chatter.steps.flavoured.Exit;
import me.construqt.ciscian.chatter.steps.flavoured.HpDisablePaging;
import me.construqt.ciscian.chatter.steps.flavoured.HpWriteMemory;
import me.construqt.ciscian.chatter.steps.flavoured.PasswordPrompt;
import me.construqt.ciscian.chatter.steps.flavoured.ShowRunningConfig;
import me.construqt.ciscian.chatter.steps.flavoured.WaitForPrompt;
import me.construqt.ciscian.chatter.steps.flavoured.Yes;
import me.construqt.ciscian.chatter.steps.generic.Case;
import me.construqt.ciscian.chatter.steps.generic.CollectOutputStep;
import me.construqt.ciscian.chatter.steps.generic.OutputConsumer;
import me.construqt.ciscian.chatter.steps.generic.Step;
import me.construqt.ciscian.chatter.steps.generic.SwitchStep;
import me.construqt.ciscian.chatter.steps.generic.WaitForStep;

public class Hp2510gSwitchChatter extends GenericCiscoFlavourSwitchChatter {

	@Override
	protected void enterManagementMode(final String username,
			final String password) {
		getOutputConsumer().addStep(new SwitchStep( //
				new Case("Press any key to continue") {
					public Step[] then() {
						return new Step[] { new EnterInput(""), new Enable(),
								new PasswordPrompt(), new EnterInput(password) };
					}
				}, new Case("Username:") {
					public Step[] then() {
						return new Step[] { //
						new EnterInput(username), //
								new PasswordPrompt(), //
								new EnterInput(password) };
					}
				}, new Case("Password:") {
					public Step[] then() {
						return new Step[] { new EnterInput(password) };
					}
				}));

		getOutputConsumer().addStep(new WaitForPrompt());
	}

	public void disablePaging() {
		getOutputConsumer().addStep(new HpDisablePaging());
		getOutputConsumer().addStep(new WaitForPrompt());
	}

	public void retrieveConfig() {
		getOutputConsumer().addStep(new ShowRunningConfig());

		getOutputConsumer().addStep(
				new WaitForStep("Running configuration:\n\r") {
					@Override
					public int performStep(StringBuffer input, PrintWriter pw,
							OutputConsumer outputConsumer) {
						return getConsumedTill();
					}
				});

		getOutputConsumer().addStep(
				new CollectOutputStep(true, "# "));
	}

	@Override
	protected void saveRunningConfig() {
		getOutputConsumer().addStep(new HpWriteMemory());
	}

	public void exit() {
		getOutputConsumer().addStep(new Exit());
		getOutputConsumer().addStep(new Exit());
		getOutputConsumer().addStep(new Yes());
	}
}
