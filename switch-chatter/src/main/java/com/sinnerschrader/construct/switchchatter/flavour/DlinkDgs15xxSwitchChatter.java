package com.sinnerschrader.construct.switchchatter.flavour;

import java.io.PrintWriter;

import com.sinnerschrader.construct.switchchatter.steps.flavoured.Enable;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.EnterInput;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.Exit;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.PasswordPrompt;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.ShowRunningConfig;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.WaitForManagementPrompt;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.WaitForPrompt;
import com.sinnerschrader.construct.switchchatter.steps.generic.CollectOutputStep;
import com.sinnerschrader.construct.switchchatter.steps.generic.CommandStep;
import com.sinnerschrader.construct.switchchatter.steps.generic.WaitForStep;

public class DlinkDgs15xxSwitchChatter extends GenericCiscoFlavourSwitchChatter {

	public void applyConfig(String config) {
		throw new RuntimeException("Not implemented.");
	}

	@Override
	protected void enterManagementMode(String password) {		
		getOutputConsumer().addStep(new PasswordPrompt());
		getOutputConsumer().addStep(new EnterInput(password));
		super.enterManagementMode(password);		
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
