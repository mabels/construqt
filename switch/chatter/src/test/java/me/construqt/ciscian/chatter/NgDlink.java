package me.construqt.ciscian.chatter;

import expect4j.Expect4j;
import me.construqt.ciscian.chatter.statemachine.Action;
import me.construqt.ciscian.chatter.statemachine.Send;
import me.construqt.ciscian.chatter.statemachine.StateMachine;
import me.construqt.ciscian.chatter.statemachine.StringOutput;
import org.junit.Test;

import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.List;
import java.util.Map;

/**
 * Created by menabe on 29.06.15.
 */
public class NgDlink {

  private StateMachine sm = new StateMachine();
  private Action helloMessage = sm.send("Hello World\n\n");
  private Action userName = sm.send("Username:").unknownCmd("unknown username");
  private Action passWord = sm.send("Password:").unknownCmd("illegal password", userName);
  private Action enableShell = sm.send("d-link#")
      .expect("exit" + Send.EOL, null, sm.EXIT)
      .unknownCmd("enable unknown command");
  private Action userShell = sm.send("d-link$")
      .expect("exit" + Send.EOL, new StringOutput("exit user level"), sm.EXIT)
      .expect("enable" + Send.EOL, null, enableShell.level())
      .unknownCmd("user unknown command");


  @Test
  public void test_Shell() throws Exception {
    helloMessage.then(userName);
    userName.expect("testUser" + Send.EOL, null, passWord);
    passWord.expect("testPwd" + Send.EOL, null, userShell);
    ServerSocket s = new ServerSocket();
    s.bind(new InetSocketAddress(4711));
    Socket conn = s.accept();
    Map<String, List<String>> log = sm.run(new Expect4j(conn.getInputStream(), conn.getOutputStream()), helloMessage);
    conn.close();

    for (Map.Entry<String, List<String>> clazz : log.entrySet()) {
      System.out.println("[" + clazz.getKey() + "]");
      for (String v : clazz.getValue()) {
        System.out.println("\t" + v);
      }
    }
  }
}
