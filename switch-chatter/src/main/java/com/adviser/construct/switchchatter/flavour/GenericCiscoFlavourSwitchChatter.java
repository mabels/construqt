package com.adviser.construct.switchchatter.flavour;

import java.io.PrintWriter;

import com.adviser.construct.switchchatter.SwitchChatter;
import com.adviser.construct.switchchatter.steps.flavoured.CiscoDisablePaging;
import com.adviser.construct.switchchatter.steps.flavoured.Enable;
import com.adviser.construct.switchchatter.steps.flavoured.EnterInput;
import com.adviser.construct.switchchatter.steps.flavoured.PasswordPrompt;
import com.adviser.construct.switchchatter.steps.flavoured.WaitForManagementPrompt;
import com.adviser.construct.switchchatter.steps.generic.CommandStep;

public abstract class GenericCiscoFlavourSwitchChatter extends SwitchChatter {
	
	public void skipSplashScreen() {
		// no splash screen exists
	}

	@Override
	protected void enterManagementMode(String password) {
		getOutputConsumer().addStep(new Enable());
		getOutputConsumer().addStep(new PasswordPrompt());
		getOutputConsumer().addStep(new EnterInput(password));
		getOutputConsumer().addStep(new WaitForManagementPrompt());
	}

	public void disablePaging() {
		getOutputConsumer().addStep(new CiscoDisablePaging());
		getOutputConsumer().addStep(new WaitForManagementPrompt());
	}


	
}
