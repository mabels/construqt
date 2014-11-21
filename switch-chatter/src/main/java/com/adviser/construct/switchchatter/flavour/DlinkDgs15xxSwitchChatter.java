package com.adviser.construct.switchchatter.flavour;

import java.io.PrintWriter;

import com.adviser.construct.switchchatter.steps.flavoured.ConfigureTerminal;
import com.adviser.construct.switchchatter.steps.flavoured.EnterInput;
import com.adviser.construct.switchchatter.steps.flavoured.Exit;
import com.adviser.construct.switchchatter.steps.flavoured.PasswordPrompt;
import com.adviser.construct.switchchatter.steps.flavoured.ShowRunningConfig;
import com.adviser.construct.switchchatter.steps.flavoured.WaitForManagementPrompt;
import com.adviser.construct.switchchatter.steps.generic.CollectOutputStep;
import com.adviser.construct.switchchatter.steps.generic.CommandStep;
import com.adviser.construct.switchchatter.steps.generic.WaitForStep;

public class DlinkDgs15xxSwitchChatter extends GenericCiscoFlavourSwitchChatter {

	public void applyConfig(String config) {
		getOutputConsumer().addStep(new ConfigureTerminal());
		getOutputConsumer().addStep(new WaitForManagementPrompt());

		String[] lines = config.split("\\n");
		for (int i = 0; i < lines.length; i++) {
			final String line = lines[i];
			getOutputConsumer().addStep(new CommandStep() {
				@Override
				public int performStep(StringBuffer input, PrintWriter pw) {
					pw.println(line);
					System.out.println("Applying config: " + line);
					return 0;
				}
			});
			getOutputConsumer().addStep(new CollectOutputStep(false, "#"));
		}

		getOutputConsumer().addStep(new Exit());
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
