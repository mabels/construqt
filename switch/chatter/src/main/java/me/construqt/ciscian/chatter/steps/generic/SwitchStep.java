package me.construqt.ciscian.chatter.steps.generic;

import java.io.PrintWriter;
import java.util.Arrays;

public class SwitchStep implements Step {

    private final Case[] cases;


    public SwitchStep(final Case... cases) {
        this.cases = cases;
    }

    @Override
    public int performStep(final StringBuffer inputBuffer, final PrintWriter terminalWriter, final OutputConsumer outputConsumer) {
        outputConsumer.insertAfterCurrentStep(findCaseMatch(inputBuffer).then());
        return 0;
    }

    @Override
    public boolean check(final StringBuffer inputBuffer) {
        return findCaseMatch(inputBuffer) != null;

    }

    private Case findCaseMatch(final StringBuffer buffer) {
        for (final Case scase : this.cases) {
            if (scase.match(buffer)) {
                return scase;
            }
        }
        return null;
    }

    @Override
    public String retrieveResult() {
        return null;
    }

    /** {@inheritDoc} */
    @Override
    public String toString() {
        final StringBuilder builder = new StringBuilder();
        builder.append("SwitchStep [cases=");
        builder.append(Arrays.toString(this.cases));
        builder.append("]");
        return builder.toString();
    }

}
