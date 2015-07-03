package me.construqt.ciscian.chatter.statemachine;

public class StringOutput implements MatchedAction {

  private final String text;

  public StringOutput(String text) {
    this.text = text;
  }

  @Override
  public void run(Output op) {
    op.sendln(text);
  }
}