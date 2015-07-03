package me.construqt.ciscian.chatter.statemachine;

import expect4j.Expect4j;
import expect4j.ExpectState;
import expect4j.matches.Match;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

public class StateMachine {
  private static final Logger LOG = LoggerFactory.getLogger(StateMachine.class);

  private Expect4j expect;

  public final static Action EXIT = new Action() {
    @Override
    public void then(Action next) {
    }

    @Override
    public Action expect(String match, MatchedAction matched, Action next) {
      return null;
    }

    @Override
    public Action next() {
      return null;
    }

    @Override
    public String text() {
      return null;
    }

    @Override
    public Action level() {
      return null;
    }

    @Override
    public Action unknownCmd(String str) {
      return null;
    }

    @Override
    public Action unknownCmd(String str, Action next) {
      return null;
    }

    @Override
    public Match[] matches() {
      return new Match[0];
    }

    @Override
    public boolean isLevel() {
      return false;
    }

    @Override
    public Action expectedNext() {
      return null;
    }

    public ExpectState getExpectState() {
      return null;
    }

    @Override
    public void resetExpectedNext() {

    }

    @Override
    public Action pop() {
      return null;
    }

    @Override
    public Action push(Action up) {
      return null;
    }

  };


  private static void addLog(Map<String, List<String>> log, String prompt, String s) {
    List<String> o = log.get(prompt);
    if (o == null) {
      o = new LinkedList<>();
      log.put(prompt, o);
    }
    o.add(s);
  }

  public Map<String, List<String>> run(Expect4j expect, Action rootAction) throws Exception {
    final Map<String, List<String>> log = new HashMap<>();
    this.expect = expect;
    expect.setDefaultTimeout(24 * 60 * 60 * 1000);
    Action current = rootAction;
    //Deque<Action> stack = new LinkedList<>();
//      if (current.isLevel()) {
//        stack.push(current);
//      }
    while (current != null) {
      if (current.text() != null) {
        addLog(log, current.text(), ">" + current.text());
        this.expect.send(current.text());
      }
      Action next = current.next();
      if (current.matches().length > 0) {
        current.resetExpectedNext();
        int ret = this.expect.expect(current.matches());
        if (current.getExpectState() != null) {
          addLog(log, current.text(), "<" + current.getExpectState().getMatch());
        }
        LOG.debug("expect>>{}", ret);
        if (ret < 0) {
          this.expect.send("\nexpect:" + ret + "\n");
        }
        if (current.expectedNext() != null) {
          next = current.expectedNext();
        } else {
          continue;
        }
      }
      if (next == EXIT) {
        current = current.pop();
        continue;
      }
      if (next != null && next != current) {
        if (next.isLevel()) {
          next.push(current);
        }
        current = next;
      }
    }
    return log;
  }

  //    public Expect4j getExpect4j() {
//       return expect;
//    }
  public Action send(String str) {
    return new Send(this, str);
  }
  public Expect4j getExpect() {
    return expect;
  }
}
 