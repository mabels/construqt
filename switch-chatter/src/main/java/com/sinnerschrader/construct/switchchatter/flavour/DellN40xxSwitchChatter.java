package com.sinnerschrader.construct.switchchatter.flavour;

import com.sinnerschrader.construct.switchchatter.steps.flavoured.Exit;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.ShowRunningConfig;
import com.sinnerschrader.construct.switchchatter.steps.generic.CollectOutputStep;
import com.sinnerschrader.construct.switchchatter.steps.generic.WaitForStep;

public class DellN40xxSwitchChatter extends GenericCiscoFlavourSwitchChatter {
	public void applyConfig(String config) {
		throw new RuntimeException("Not implemented.");
	}

	public void retrieveConfig() {
		getOutputConsumer().addStep(new ShowRunningConfig());
		getOutputConsumer().addStep(new WaitForStep("!Current Configuration:"));
		getOutputConsumer().addStep(new WaitForStep("\n"));
		getOutputConsumer().addStep(new CollectOutputStep(false, "\n\r"));
	}

	public void exit() {
		getOutputConsumer().addStep(new Exit());
		getOutputConsumer().addStep(new Exit());
	}
}
