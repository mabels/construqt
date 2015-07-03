package me.construqt.ciscian.chatter.flavour;

import org.apache.commons.lang.NotImplementedException;

//import me.construqt.ciscian.chatter.steps.flavoured.Exit;
//import me.construqt.ciscian.chatter.steps.generic.WaitForStep;

public class DellN40xxSwitchChatter extends GenericCiscoFlavourSwitchChatter {


	public void applyConfig(String config) {
		throw new RuntimeException("Not implemented.");
	}

//	public void retrieveConfig() {
//		getFromDeviceConsumer().addStep(new ShowRunningConfig());
//		getFromDeviceConsumer().addStep(new WaitForStep("!Current Configuration:"));
//		getFromDeviceConsumer().addStep(new WaitForStep("\n"));
//		getFromDeviceConsumer().addStep(new CollectOutputStep(false, "\n\r"));
//	}

	public void exit() {
	}

//	@Override
//	protected void saveRunningConfig() {
//		throw new NotImplementedException(
//				"Saving is not implemented in this flavour.");
//	}

}
