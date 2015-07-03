package me.construqt.ciscian.chatter.steps.generic;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.OutputStream;
import java.io.PrintWriter;

/**
 * Created by menabe on 18.05.15.
 */
public class Writer {

  private static final Logger LOG = LoggerFactory.getLogger(Writer.class);


  private PrintWriter printWriter;

  public Writer(OutputStream os) {
    printWriter = new PrintWriter(os, true);
  }

  public void println(String out) {
    LOG.debug("println:"+out);
    printWriter.println(out);
    printWriter.flush();
  }
  public void print(String out) {
    LOG.debug("print:"+out);
    printWriter.print(out);
    printWriter.flush();
  }
}
