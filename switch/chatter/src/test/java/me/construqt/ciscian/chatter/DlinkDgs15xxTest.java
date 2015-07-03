package me.construqt.ciscian.chatter;

import com.sun.org.apache.xalan.internal.xsltc.compiler.util.StringStack;
import expect4j.Expect4j;
import org.apache.commons.io.IOUtils;
import org.apache.commons.net.io.SocketInputStream;
import org.apache.commons.net.io.SocketOutputStream;
import org.junit.BeforeClass;
import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Stack;
import java.util.concurrent.BlockingDeque;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.LinkedBlockingQueue;


public class DlinkDgs15xxTest {

  private static final Logger LOG = LoggerFactory.getLogger(DlinkDgs15xxTest.class);

  @BeforeClass
  public static void registerFlavour() {
    Main.registerFlavours();
  }

  public static class MockDlinkDgs15xx {

    private final PipedInputStream othersInput = new PipedInputStream(1024);
    private final PipedOutputStream myOutput;

    private final PipedInputStream myInput = new PipedInputStream(1024);
    private final PipedOutputStream othersOutput;

    private final SwitchSession sw;
    private Thread mockServer;

    protected MockDlinkDgs15xx() throws IOException {
      myOutput = new PipedOutputStream(othersInput);
      othersOutput = new PipedOutputStream(myInput);
      sw = SwitchFactory.create("DlinkDgs15xx", othersInput, othersOutput, true, false);
    }

    public static SwitchSession start(final SwitchSession.SwitchAction... actions) throws IOException {

      final MockDlinkDgs15xx mock = new MockDlinkDgs15xx();
      mock.mockServer = new Thread(new Runnable() {
        @Override
        public void run() {
          LOG.debug("Start");
          try {
            SwitchSession my = SwitchFactory.create("DlinkDgs15xx", mock.myInput, mock.myOutput, true, false);
            my.setDefaultTimeout(24*60*60*1000);
            for (SwitchSession.SwitchAction action : actions) {
              my.pushAction(action);
            }
            my.run();
          } catch (Exception e) {
            LOG.error("Exception:", e);
          }
          LOG.debug("Stopped");
        }
      });
      mock.mockServer.setName(mock.getClass().getSimpleName());
      mock.mockServer.start();
      return mock.sw;
    }

//  public boolean completed() {
//    return countDownLatch.getCount() == 0;
//  }

    public void stop() {
      //sw.stop();
      IOUtils.closeQuietly(myOutput);
      IOUtils.closeQuietly(othersOutput);
      IOUtils.closeQuietly(myInput);
      IOUtils.closeQuietly(othersInput);
    }

  }


  private static SwitchSession.SwitchAction runEnableShell() {
    return new SwitchSession.Send("d-link#",
        new SwitchSession.Expect(new SwitchSession.CaseAction() {
          @Override
          public boolean action(SwitchSession sc) throws Exception {
            sc.send("exiting enable mode");
            return false;
          }
        }, "(exit)([\r|\n]+)"),
        new SwitchSession.Expect(new SwitchSession.CaseAction() {
              @Override
              public boolean action(SwitchSession sc) throws Exception {
                sc.send("unknown cmd\n");
                return true;
              }
            }, "(\\S*)([\r|\n]+)")
        );
  }

  private final SwitchSession.SwitchAction enableAction = runEnableShell();


  private static SwitchSession.SwitchAction runUserShell() {
    return new SwitchSession.Send("d-link>",
        new SwitchSession.Expect(new SwitchSession.CaseAction() {
          @Override
          public boolean action(SwitchSession sc) throws Exception {
            sc.pushAction(runEnableShell());
            return false;
          }
        }, "enable([\n|\r]+)"),
          new SwitchSession.Expect(new SwitchSession.CaseAction() {
            @Override
            public boolean action(SwitchSession sc) throws Exception {
              sc.send("closing connection\n");
              return false;
            }
          }, "exit([\r|\n]+)"),
        new SwitchSession.Expect(new SwitchSession.CaseAction() {
          @Override
          public boolean action(SwitchSession sc) throws Exception {
            sc.send("unknown cmd\n");
            return true;
          }
        }, "(\\S*)([\r|\n]+)"));

//    }, );
  }

  private final SwitchSession.SwitchAction userAction = runUserShell();


  private SwitchSession.SwitchAction runAskUserPasswordTo(final SwitchSession.SwitchAction next) {
    return runAskUserTo(next);
  }

  private SwitchSession.SwitchAction runAskUsernamePasswordToEnable() {
    return runAskUserPasswordTo(enableAction);
  }

  private SwitchSession.SwitchAction runAskUsernamePasswordToUser() {
    return runAskUserPasswordTo(userAction);
  }

  private SwitchSession.SwitchAction runAskPasswordTo(final SwitchSession.SwitchAction next) {
    return new SwitchSession.Send("d-link Password:",
        new SwitchSession.Expect(new SwitchSession.CaseAction() {
          @Override
          public boolean action(SwitchSession sc) throws Exception {
            if ("userPW".equals(sc.getExpectState().getMatch(1))) {
              sc.pushAction(next);
              return false;
            }
            return true;
          }
        }, "(\\S*)([\r|\n]+)"));
  }


  private SwitchSession.SwitchAction runAskPasswordToEnable() {
    return runAskPasswordTo(enableAction);
  }

  private SwitchSession.SwitchAction runAskPasswordToUser() {
    return runAskPasswordTo(userAction);
  }

  private SwitchSession.SwitchAction runAskUserTo(final SwitchSession.SwitchAction next) {
    return new SwitchSession.Send( "d-link Username:",
        new SwitchSession.Expect(new SwitchSession.CaseAction() {
          @Override
          public boolean action(SwitchSession sc) throws Exception {
            if (sc.getExpectState().getMatch(1).equals("Test")) {
              sc.pushAction(next);
            }
            return true;
          }
        }, "(\\S+)([\r|\n]$)"));
  }

  private SwitchSession.SwitchAction runAskUserToUser() {
    return runAskUserTo(userAction);
  }


  private SwitchSession.SwitchAction runAskUserToEnable() {
    return runAskUserTo(enableAction);
  }



  @Test
  public void test_LoginViaUserToUser() throws Exception {
    final SwitchSession sc = MockDlinkDgs15xx.start(
        new SwitchSession.Send("Hello Dlink Mock\n\n"),
        runAskUserToUser()
    );

    sc.login("Test", "userPW");
    sc.enterManagementMode("enablePW");
    sc.close();
  }


  @Test
  public void test_LoginViaUserToEnable() throws Exception {
    final SwitchSession sc = MockDlinkDgs15xx.start(
        new SwitchSession.Send("Hello Dlink Mock\n\n"),
        runAskUserToEnable()
    );

    sc.login("Test", "userPW");
    sc.enterManagementMode("enablePW");
    sc.close();
  }


  @Test
  public void test_LoginViaPasswordToUser() throws Exception {
    final SwitchSession sc = MockDlinkDgs15xx.start(
        new SwitchSession.Send("Hello Dlink Mock\n\n"),
        runAskPasswordToUser()
    );

    sc.login("Test", "userPW");
    sc.enterManagementMode("enablePW");
    sc.close();
  }

  @Test
  public void test_LoginViaPasswordToEnable() throws Exception {
    final SwitchSession sc = MockDlinkDgs15xx.start(
        new SwitchSession.Send("Hello Dlink Mock\n\n"),
        runAskPasswordToEnable()
    );

    sc.login("Test", "userPW");
    sc.enterManagementMode("enablePW");
    sc.close();
  }


  @Test
  public void test_LoginViaUserPasswordToUser() throws Exception {
    final SwitchSession sc = MockDlinkDgs15xx.start(
        new SwitchSession.Send("Hello Dlink Mock\n\n"),
        runAskUsernamePasswordToUser()
    );
    sc.login("Test", "userPW");
    sc.enterManagementMode("enablePW");
    sc.close();
  }

  @Test
  public void test_LoginViaUserPasswordToEnable() throws Exception {
    final SwitchSession sc = MockDlinkDgs15xx.start(
        new SwitchSession.Send("Hello Dlink Mock\n\n"),
        runAskUsernamePasswordToEnable()
    );
    sc.login("Test", "userPW");
    sc.enterManagementMode("enablePW");
    sc.close();
  }

  // Done
  @Test
  public void test_DirectToUser() throws Exception {
    final SwitchSession sc = MockDlinkDgs15xx.start(
        new SwitchSession.Send("Hello Dlink Mock\n\n"),
        runUserShell()
    );
    sc.login("Test", "userPW");
    sc.enterManagementMode("enablePW");
    sc.close();
  }

  // Done
  @Test
  public void test_DirectToEnable() throws Exception {
    final SwitchSession sc = MockDlinkDgs15xx.start(
        new SwitchSession.Send("Hello Dlink Mock\n\n"),
        runEnableShell()
    );

    sc.login("Test", "userPW");
    sc.enterManagementMode("enablePW");
    sc.close();
  }


  @Test
  public void test_TcpServer() throws Exception {
    ServerSocket s = new ServerSocket();
    s.bind(new InetSocketAddress(4711));
    Socket conn = s.accept();

    SwitchSession my = SwitchFactory.create("DlinkDgs15xx", conn.getInputStream(), conn.getOutputStream(), true, false);
    my.setDefaultTimeout(24*60*60*1000);

    my.pushAction(new SwitchSession.Send("Hello Dlink Mock\n\n"), runAskPasswordToUser());

    my.run();

    conn.close();

  }

  @Test
  public void test_getConfig() throws Exception {
//
//
//    Connector connector = ConnectorFactory.createConnector("ssh://[2a04:2f80:0:1726::12:2]:22",
//        "root", "imd9SiVZ1yVXjl");
//    ConnectResult connect = connector.connect();
//
//    final SwitchSession sc = SwitchFactory.create("DlinkDgs15xx", connect.getInputStream(),
//        connect.getOutputStream(), true, false);
//    sc.login("root", "imd9SiVZ1yVXjl");
//    sc.enterManagementMode("imd9SiVZ1yVXjl");
//    sc.retrieveConfig();
//    sc.close();
  }

}