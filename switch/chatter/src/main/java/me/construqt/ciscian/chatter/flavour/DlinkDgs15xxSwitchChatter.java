package me.construqt.ciscian.chatter.flavour;

import me.construqt.ciscian.chatter.steps.flavoured.EnterInput;
import me.construqt.ciscian.chatter.steps.flavoured.Exit;
import me.construqt.ciscian.chatter.steps.flavoured.PasswordPrompt;
import me.construqt.ciscian.chatter.steps.flavoured.ShowRunningConfig;
import me.construqt.ciscian.chatter.steps.generic.CollectOutputStep;
import me.construqt.ciscian.chatter.steps.generic.WaitForStep;

public class DlinkDgs15xxSwitchChatter extends GenericCiscoFlavourSwitchChatter {



	@Override
	protected void enterManagementMode(String user, String password) {
		getOutputConsumer().addStep(new PasswordPrompt());
		getOutputConsumer().addStep(new EnterInput(password));
		super.enterManagementMode(user, password);
	}

	public void retrieveConfig() {
		getOutputConsumer().addStep(new ShowRunningConfig());
		getOutputConsumer().addStep(new WaitForStep("Current configuration :"));
		getOutputConsumer().addStep(new WaitForStep("\n\r"));
		getOutputConsumer().addStep(new WaitForStep("\n\r"));
		getOutputConsumer().addStep(
				new CollectOutputStep(false, "End of configuration file", "#",
						"\n\r", "\n\r"));
	}

	public void exit() {
		getOutputConsumer().addStep(new Exit());
	}

}
