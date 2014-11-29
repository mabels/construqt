package me.construqt.ciscian.chatter.flavour;

import java.io.PrintWriter;

import me.construqt.ciscian.chatter.SwitchChatter;
import me.construqt.ciscian.chatter.steps.flavoured.CiscoDisablePaging;
import me.construqt.ciscian.chatter.steps.flavoured.ConfigureTerminal;
import me.construqt.ciscian.chatter.steps.flavoured.Enable;
import me.construqt.ciscian.chatter.steps.flavoured.EnterInput;
import me.construqt.ciscian.chatter.steps.flavoured.Exit;
import me.construqt.ciscian.chatter.steps.flavoured.PasswordPrompt;
import me.construqt.ciscian.chatter.steps.flavoured.WaitForPrompt;
import me.construqt.ciscian.chatter.steps.generic.CollectOutputStep;
import me.construqt.ciscian.chatter.steps.generic.CommandStep;
import me.construqt.ciscian.chatter.steps.generic.OutputConsumer;

public abstract class GenericCiscoFlavourSwitchChatter extends SwitchChatter {

	public void applyConfig(String config) {
		getOutputConsumer().addStep(new ConfigureTerminal());
		getOutputConsumer().addStep(new WaitForPrompt());

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
		getOutputConsumer().addStep(new WaitForPrompt());
	}

	public void disablePaging() {
		getOutputConsumer().addStep(new CiscoDisablePaging());
		getOutputConsumer().addStep(new WaitForPrompt());
	}

}
