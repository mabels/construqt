package me.construqt.ciscian.chatter.statemachine;

import expect4j.Closure;
import expect4j.ExpectState;
import expect4j.matches.Match;
import expect4j.matches.RegExpMatch;
import org.apache.oro.text.regex.MalformedPatternException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.LinkedList;
import java.util.List;

public class Send implements Action {

  private static final Logger LOG = LoggerFactory.getLogger(Send.class);

  public static final String EOL = "([\r|\n]+)";

  private static class Expecter {
    public final String match;
    public final MatchedAction matched;
    public final Action next;

    public Expecter(String match, final MatchedAction matched, final Action next) {
      this.match = match;
      this.matched = matched;
      this.next = next;
    }
  }

  private Action next;
  private Action expectNext;
  private final String text;
  private boolean level = false;
  private List<Expecter> matchList = new LinkedList<>();
  private final StateMachine sm;
  private final MatchedAction.Output output;
  private Expecter unknownCmd = null;
  private Action previous = null;
  private ExpectState expectState;


  private Send(Send other) {
    next = other.next;
    expectNext = other.expectNext;
    text = other.text;
    level = other.level;
    matchList = new LinkedList<>(other.matchList);
    sm = other.sm;
    output = other.output;
    unknownCmd = other.unknownCmd;
    previous = other.previous;
    expectState = other.expectState;
  }

  public Send(StateMachine sm, String text) {
    this.sm = sm;
    this.text = text;
    output = new MatchedAction.Output(sm);
  }

  @Override
  public void then(Action next) {
    this.next = next;
  }

  private RegExpMatch buildRegExpMatch(final Expecter expecter) {
    final Closure closure = new Closure() {
      public void run(ExpectState es) throws Exception {
        Send.this.expectNext = expecter.next;
        Send.this.expectState = es;
        if (expecter.matched != null) {
          expecter.matched.run(output);
        }
      }
    };
    try {
      return new RegExpMatch(expecter.match, closure);
    } catch (MalformedPatternException e) {
      LOG.error("illegal match:{}", e);
    }
    return null;
  }

  @Override
  public Action expect(String match, final MatchedAction matched, final Action next) {
    matchList.add(new Expecter(match, matched, next));
    return this;
  }

  public Action unknownCmd(final String str) {
    return unknownCmd(str, null);
  }

  public Action unknownCmd(final String str, final Action next) {
    unknownCmd = new Expecter("(\\S*)" + EOL, new StringOutput(str), next);
    return this;
  }

  public String text() {
    return text;
  }

  @Override
  public Action level() {
    Send ret = new Send(this);
    ret.level = true;
    return ret;
  }

  @Override
  public Match[] matches() {
    // optimize this mess
    int len = matchList.size();
    if (unknownCmd != null) {
      ++len;
    }
    Match[] ret = new Match[len];
    int i = 0;
    for (Expecter e : matchList) {
      ret[i++] = buildRegExpMatch(e);
    }
    if (unknownCmd != null) {
      ret[i++] = buildRegExpMatch(unknownCmd);
    }
    return ret;
  }

  @Override
  public boolean isLevel() {
    return level;
  }

  public Action next() {
    return next;
  }

  public Action expectedNext() {
    return expectNext;
  }

  public void resetExpectedNext() {
    this.expectNext = null;
  }

  public Action push(Action up) {
    previous = up;
    return this;
  }

  public Action pop() {
    return previous;
  }

  public ExpectState getExpectState() {
    return expectState;
  }
}