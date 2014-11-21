package com.adviser.construct.switchchatter.flavour;

import com.adviser.construct.switchchatter.steps.flavoured.EnterInput;
import com.adviser.construct.switchchatter.steps.flavoured.Exit;
import com.adviser.construct.switchchatter.steps.flavoured.PasswordPrompt;
import com.adviser.construct.switchchatter.steps.flavoured.ShowRunningConfig;
import com.adviser.construct.switchchatter.steps.generic.CollectOutputStep;
import com.adviser.construct.switchchatter.steps.generic.WaitForStep;

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
