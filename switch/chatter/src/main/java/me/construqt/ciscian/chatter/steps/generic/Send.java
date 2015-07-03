package me.construqt.ciscian.chatter.steps.generic;

/**
 * Created by menabe on 18.05.15.
 */
public class Send extends Step {
  final String data;
  public Send(String data) {
    this.data = data;
  }
  public String send() {
    return data;
  }
}
