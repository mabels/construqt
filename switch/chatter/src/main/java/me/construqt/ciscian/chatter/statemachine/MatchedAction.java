package me.construqt.ciscian.chatter.statemachine;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

interface MatchedAction {
    static class Output {
      private static final Logger LOG = LoggerFactory.getLogger(Output.class);

      private final StateMachine sm;
      protected Output(StateMachine sm) {
        this.sm = sm;
      }
      public void sendln(String s) {
        send(s + "\n");
      }
      public void send(String s) {
        try {
          sm.getExpect().send(s);
        } catch (IOException e) {
          LOG.error("send failed:", e);
        }
      }
    }
    void run(Output op);
  }