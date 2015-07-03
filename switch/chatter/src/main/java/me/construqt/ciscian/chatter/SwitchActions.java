package me.construqt.ciscian.chatter;

/**
 * Created by menabe on 19.05.15.
 */
public interface SwitchActions {

  void login(final String username, final String password) throws Exception;

  void enterManagementMode(String enablePassword) throws Exception;

  //protected abstract void disablePaging();

  void applyConfig(String config);

  StringBuilder retrieveConfig() throws Exception;

  void exit() throws Exception;

  void saveRunningConfig() throws Exception;

  void setSession(SwitchSession session);


}
