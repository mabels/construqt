package me.construqt.ciscian.chatter.statemachine;

import expect4j.ExpectState;
import expect4j.matches.Match;

/**
 * Created by menabe on 03.07.15.
 */
public interface Action{
  void then(Action next);
  Action expect(String match, final MatchedAction matched, Action next);
  Action next();
  String text();
  Action level();

  Action unknownCmd(String str);
  Action unknownCmd(String str, Action next);
  Match[] matches();
  boolean isLevel();
  Action expectedNext();
  ExpectState getExpectState();
  void resetExpectedNext();

  Action pop();
  Action push(Action up);
}
