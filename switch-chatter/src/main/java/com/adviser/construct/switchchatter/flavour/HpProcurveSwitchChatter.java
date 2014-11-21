package com.adviser.construct.switchchatter.flavour;

import java.io.PrintWriter;

import com.adviser.construct.switchchatter.steps.flavoured.EnterInput;
import com.adviser.construct.switchchatter.steps.flavoured.Exit;
import com.adviser.construct.switchchatter.steps.flavoured.HpDisablePaging;
import com.adviser.construct.switchchatter.steps.flavoured.PasswordPrompt;
import com.adviser.construct.switchchatter.steps.flavoured.ShowRunningConfig;
import com.adviser.construct.switchchatter.steps.flavoured.WaitForManagementPrompt;
import com.adviser.construct.switchchatter.steps.flavoured.Yes;
import com.adviser.construct.switchchatter.steps.generic.Case;
import com.adviser.construct.switchchatter.steps.generic.CollectOutputStep;
import com.adviser.construct.switchchatter.steps.generic.OutputConsumer;
import com.adviser.construct.switchchatter.steps.generic.Step;
import com.adviser.construct.switchchatter.steps.generic.SwitchStep;
import com.adviser.construct.switchchatter.steps.generic.WaitForStep;

public class HpProcurveSwitchChatter extends GenericCiscoFlavourSwitchChatter {

	@Override
	protected void enterManagementMode(String username, String password) {
		getOutputConsumer().addStep(new SwitchStep( //
				new Case("Press any key to continue") {
					public Step[] then() {
						return new Step[] { new EnterInput("") };
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

		getOutputConsumer().addStep(new WaitForManagementPrompt());
	}

	public void disablePaging() {
		getOutputConsumer().addStep(new HpDisablePaging());
		getOutputConsumer().addStep(new WaitForManagementPrompt());
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
				new CollectOutputStep(false, "" + (char) 27));
	}

	public void exit() {
		getOutputConsumer().addStep(new Exit());
		getOutputConsumer().addStep(new Exit());
		getOutputConsumer().addStep(new Yes());
	}
}
