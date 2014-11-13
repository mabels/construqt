package com.sinnerschrader.construct.switchchatter.flavour;

import java.io.PrintWriter;

import com.sinnerschrader.construct.switchchatter.SwitchChatter;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.ConfigureTerminal;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.Exit;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.HpDisablePaging;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.HpSkipSplashScreen;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.ShowRunningConfig;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.WaitForPrompt;
import com.sinnerschrader.construct.switchchatter.steps.flavoured.Yes;
import com.sinnerschrader.construct.switchchatter.steps.generic.CollectOutputStep;
import com.sinnerschrader.construct.switchchatter.steps.generic.CommandStep;
import com.sinnerschrader.construct.switchchatter.steps.generic.WaitForStep;

public class HpProcurveSwitchChatter extends SwitchChatter {

	public void skipSplashScreen() {
		getOutputConsumer().addStep(new HpSkipSplashScreen());
		getOutputConsumer().addStep(new WaitForPrompt());
	}

	@Override
	protected void enterManagementMode(String password) {
		// switch is automatically in management mode
	}

	public void disablePaging() {
		getOutputConsumer().addStep(new HpDisablePaging());
		getOutputConsumer().addStep(new WaitForPrompt());
	}

	public void applyConfig(String config) {
		getOutputConsumer().addStep(new ConfigureTerminal());
		getOutputConsumer().addStep(new WaitForPrompt());

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

	public void retrieveConfig() {
		getOutputConsumer().addStep(new ShowRunningConfig());

		getOutputConsumer().addStep(
				new WaitForStep("Running configuration:\n\r") {
					@Override
					public int performStep(StringBuffer input, PrintWriter pw) {
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
