package me.construqt.ciscian.chatter;

import expect4j.Closure;
import expect4j.Expect4j;
import expect4j.ExpectState;
import expect4j.matches.Match;
import expect4j.matches.RegExpMatch;
import org.apache.commons.lang.mutable.MutableBoolean;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.Vector;
import java.util.concurrent.*;

/**
 * Created by menabe on 19.05.15.
 */
public class SwitchSession implements SwitchActions {

  private static final Logger LOG = LoggerFactory.getLogger(SwitchSession.class);

  private final SwitchActions switchActions;
  private final InputStream is;
  private final OutputStream os;
  private String promptPrefix = "([\\w]+)";
  private final Expect4j expect;
  private final ArrayList<SwitchAction[]> actions = new ArrayList<>();

  private ExpectState expectState = null;

  public interface Step {
    boolean run(SwitchSession ss) throws Exception;
  }

  public interface CaseAction {
    /*
     * @return null stay in this, !null jump to declared.
     */
    boolean action(SwitchSession sc) throws Exception;
  }

  public interface SwitchAction {
    //boolean run(SwitchSession ss) throws Exception;

    Step[] getSteps();
//    CaseAction getAction();
  }

  public static class Send implements SwitchAction {
    private final String prompt;
    private final Expect[] expects;

    public Send(String prompt, Expect ...expects) {
      this.expects = expects;
      this.prompt = prompt;
    }

    public Step[] getSteps() {
      return new Step[]{
          new Step() {
            @Override
            public boolean run(SwitchSession ss) throws Exception {
              LOG.debug("send:run:{}", Util.replaceAllTerminalControlCharacters(prompt));
              ss.send(prompt);
              return false;
            }
          },
          new Step() {
            @Override
            public boolean run(SwitchSession ss) throws Exception {
              MutableBoolean repeat = new MutableBoolean();
              if (expects != null && expects.length > 0) {
                ss.getExpect().expect(ss.match(repeat, expects));
              }
              return repeat.toBoolean();
            }
          }
      };
    }

//    public CaseAction getAction() {
//      return expects;
//    }

//    public String[] getToken() {
//      return tokens;
//    }

//    public boolean run(SwitchSession ss) throws Exception {
//    }
  }

  public static class Expect implements SwitchAction {
    private final String[] tokens;
    private final CaseAction action;

    public Expect(CaseAction action, String ...tokens) {
      this.tokens = tokens;
      this.action = action;
    }

    public CaseAction getAction() {
      return action;
    }

    public String[] getToken() {
      return tokens;
    }

    public Step[] getSteps() {
      return null;
    }

    public boolean run(SwitchSession ss) throws Exception {
      LOG.debug("expect:run:[{}]", Util.replaceAllTerminalControlCharacters(tokens));
      MutableBoolean repeat = new MutableBoolean();
      ss.getExpect().expect(ss.match(repeat, this));
      return repeat.toBoolean();
    }

  }

  public SwitchSession(SwitchActions actions, InputStream is, OutputStream os) {
    this.switchActions = actions;
    actions.setSession(this);
    this.os = os;
    this.is = is;
    this.expect = new Expect4j(is, os);
  }

//  public void pushActions(SwitchAction[] sas) {
//    for (SwitchAction sa : sas) {
//      actions.add(sa);
//    }
//  }

  public void setDefaultTimeout(long timeout) {
    this.expect.setDefaultTimeout(timeout);
  }

  public void pushAction(SwitchAction ...sas) {
   // for (SwitchAction sa : sas) {
      actions.add(sas);
  //  }
  }


  public void run() {
    int pos = 0;
    while(true) {
      try {
        final int size = actions.size();
        LOG.debug("q:{}", size);
        if (size == 0) {
           break;
        }
        SwitchAction[] sas = actions.get(size-1);
        if (size > 1) {
          actions.remove(size-1);
        }
        boolean repeat = true;
          do {
            for (SwitchAction sa : sas) {

              for (Step step : sa.getSteps()) {
                repeat = step.run(this);
                if (repeat) {
                  break;
                }
              }
            }
          } while (repeat);

      } catch (Exception e) {
        LOG.error("Run-Failed:", e);
      }
    }
  }
  public List<Match> match(final Expect ...cases) throws Exception {
    return match(new MutableBoolean(), cases);
  }

  public List<Match> match(final MutableBoolean repeat, final Expect ...cases) throws Exception {

    final StringBuilder sb = new StringBuilder();
    final List<Match> lstPattern =  new ArrayList<Match>();
    String comma = "";
    for (final Expect caze: cases) {
      final Closure closure = new Closure() {
        public void run(ExpectState es) throws Exception {
          expectState = es;
          //buffer.append(expectState.getBuffer());//string buffer for appending output of executed command
          LOG.debug("<<{}[{}] found:[{}]", Util.replaceAllTerminalControlCharacters(expectState.getMatch()),
              Util.replaceAllTerminalControlCharacters(expectState.getBuffer()),
              Util.replaceAllTerminalControlCharacters(caze.getToken()));
          repeat.setValue(caze.getAction().action(SwitchSession.this));
        }
      };

      for (String token : caze.getToken()) {
        try {
          Match mat = new RegExpMatch(token, closure);
          sb.append(comma);
          comma = ",";
          sb.append(Util.replaceAllTerminalControlCharacters(token));
          lstPattern.add(mat);
        } catch (Exception e) {
          LOG.error("match:", e);
        }
      }
      //queueAction.add(caze);
    }
    LOG.debug("match:[{}]", sb);
    return lstPattern;
//    expect.expect(lstPattern);
  }

  public void setSession(SwitchSession a) {
    throw new RuntimeException("do not call this");
  }

  public void sendln(String s) throws IOException {
    send(s + "\n");
  }
  public void send(String s) throws IOException {
    LOG.debug(">>{}", Util.replaceAllTerminalControlCharacters(s));
    expect.send(s);
  }

//  public void expectUser() {
//
//  }
//  public void expectEnable() {
//
//  }

  public void learnPrompt() {
    String match = expectState.getMatch();
    promptPrefix = match.substring(1, match.length() - 1);
    LOG.debug("prompt:{}", promptPrefix);
  }

//  public void expectPrompt(String ...patterns) {
//  }

  public void expect(String ...patterns) throws Exception {
    MutableBoolean repeat = new MutableBoolean();
    match(repeat, new Expect(new CaseAction() {
      @Override
      public  boolean action(SwitchSession ss) throws Exception {
        return false;
      }
    }, patterns));
  }

  public ExpectState getExpectState() {
    return expectState;
  }

  public Expect4j getExpect() {
    return expect;
  }


  public String getEnablePrompt() {
    return "(\n|\r)"+promptPrefix+"#";
  }

  public String getUserPrompt() {
    return "(\n|\r)"+promptPrefix+">";
  }


  public void close() {
    expect.close();
  }

  @Override
  public void login(String username, String password) throws Exception {
    switchActions.login(username, password);
  }

  @Override
  public void enterManagementMode(String enablePassword) throws Exception {
    switchActions.enterManagementMode(enablePassword);
  }

  @Override
  public void applyConfig(String config) {
     switchActions.applyConfig(config);
  }

  @Override
  public StringBuilder retrieveConfig() throws Exception {
    return switchActions.retrieveConfig();
  }

  @Override
  public void exit() throws Exception {
     switchActions.exit();
  }

  @Override
  public void saveRunningConfig() throws Exception {
    switchActions.saveRunningConfig();
  }



}
