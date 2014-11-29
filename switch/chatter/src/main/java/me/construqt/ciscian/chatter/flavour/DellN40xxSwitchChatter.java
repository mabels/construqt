package me.construqt.ciscian.chatter.flavour;

import me.construqt.ciscian.chatter.steps.flavoured.Exit;
import me.construqt.ciscian.chatter.steps.flavoured.ShowRunningConfig;
import me.construqt.ciscian.chatter.steps.generic.CollectOutputStep;
import me.construqt.ciscian.chatter.steps.generic.WaitForStep;

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
