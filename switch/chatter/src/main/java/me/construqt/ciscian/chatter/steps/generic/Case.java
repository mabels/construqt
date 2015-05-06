package me.construqt.ciscian.chatter.steps.generic;

public abstract class Case {

    private final String waitFor;


    public Case(final String waitFor) {
        this.waitFor = waitFor;
    }

    public abstract Step[] then();

    public boolean match(final StringBuffer buffer) {
        return buffer.indexOf(this.waitFor) >= 0;
    }

    /** {@inheritDoc} */
    @Override
    public String toString() {
        final StringBuilder builder = new StringBuilder();
        builder.append("Case [waitFor=");
        builder.append(this.waitFor);
        builder.append("]");
        return builder.toString();
    }

}
