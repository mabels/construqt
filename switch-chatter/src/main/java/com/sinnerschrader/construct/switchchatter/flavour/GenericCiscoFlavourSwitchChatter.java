package com.sinnerschrader.construct.switchchatter.flavour;

import java.io.PrintWriter;

import com.sinnerschrader.construct.switchchatter.SwitchChatter;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.CiscoDisablePaging;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.Enable;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.PasswordPrompt;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.WaitForPrompt;
import com.sinnerschrader.construct.switchchatter.steps.generic.CommandStep;

public abstract class GenericCiscoFlavourSwitchChatter extends SwitchChatter {
	
	public void skipSplashScreen() {
		// no splash screen exists
	}

	@Override
	protected void enterManagementMode(String password) {
		getOutputConsumer().addStep(new Enable());
		getOutputConsumer().addStep(new PasswordPrompt());
		getOutputConsumer().addStep(new CommandStep() {
			@Override
			public int performStep(StringBuffer inputBuffer,
					PrintWriter terminalWriter) {
				terminalWriter.println(password);
				return 0;
			}
		});
		getOutputConsumer().addStep(new WaitForPrompt());
	}

	public void disablePaging() {
		getOutputConsumer().addStep(new CiscoDisablePaging());
		getOutputConsumer().addStep(new WaitForPrompt());
	}


	
}
