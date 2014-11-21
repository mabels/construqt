package com.adviser.construct.switchchatter.flavour;

import java.io.PrintWriter;

import com.adviser.construct.switchchatter.SwitchChatter;
import com.adviser.construct.switchchatter.steps.flavoured.CiscoDisablePaging;
import com.adviser.construct.switchchatter.steps.flavoured.ConfigureTerminal;
import com.adviser.construct.switchchatter.steps.flavoured.Enable;
import com.adviser.construct.switchchatter.steps.flavoured.EnterInput;
import com.adviser.construct.switchchatter.steps.flavoured.Exit;
import com.adviser.construct.switchchatter.steps.flavoured.PasswordPrompt;
import com.adviser.construct.switchchatter.steps.flavoured.WaitForConfigureTerminalPrompt;
import com.adviser.construct.switchchatter.steps.flavoured.WaitForManagementPrompt;
import com.adviser.construct.switchchatter.steps.generic.CollectOutputStep;
import com.adviser.construct.switchchatter.steps.generic.CommandStep;
import com.adviser.construct.switchchatter.steps.generic.OutputConsumer;

public abstract class GenericCiscoFlavourSwitchChatter extends SwitchChatter {

	public void applyConfig(String config) {
		getOutputConsumer().addStep(new ConfigureTerminal());
		getOutputConsumer().addStep(new WaitForConfigureTerminalPrompt());

		String[] lines = config.split("\\n");
		for (int i = 0; i < lines.length; i++) {
			final String line = lines[i];
			getOutputConsumer().addStep(new CommandStep() {
				@Override
				public int performStep(StringBuffer input, PrintWriter pw, OutputConsumer outputConsumer) {
					pw.println(line);
					System.out.println("Applying config: " + line);
					return 0;
				}
			});
			getOutputConsumer().addStep(
					new CollectOutputStep(false, "#"));
		}

		getOutputConsumer().addStep(new Exit());
	}

	@Override
	protected void enterManagementMode(String user, String password) {
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
