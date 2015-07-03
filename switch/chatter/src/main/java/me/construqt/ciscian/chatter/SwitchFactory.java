package me.construqt.ciscian.chatter;

import expect4j.Closure;
import expect4j.Expect4j;
import expect4j.ExpectState;
import expect4j.matches.Match;
import expect4j.matches.RegExpMatch;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Future;

public abstract class SwitchFactory {

	private static final Logger LOG = LoggerFactory.getLogger(SwitchFactory.class);

//	private OutputStream os;
//
//	private InputStream is;

	//private FromDeviceConsumer fromDeviceConsumer;

//	protected Expect4j expect;
//
//	private CountDownLatch stepsDone = new CountDownLatch(1);
//
//	public void setStepsDone() {
//		stepsDone.countDown();
//	}
//
//	public void waitStepsDone() throws InterruptedException {
//		stepsDone.await();
//	}

	public interface Factory {
		String getName();
		SwitchActions getInstance();
	}

	private static Map<String, Factory> factory = new HashMap<>();

	public static boolean registerSwitchChatterFactory(Factory scf) {
		LOG.debug("register="+scf.getName());
		factory.put(scf.getName(), scf);
		return true;
	}

	private SwitchFactory() {
	}

//	public void stop() {
//		expect.close();
//	}

	private static String convertFlavourName(String flavour) {
		int i = -1;
		flavour = flavour.substring(0, 1).toUpperCase() + flavour.substring(1);
		while ((i = flavour.indexOf('-')) >= 0) {
			flavour = flavour.substring(0, i)
					+ flavour.substring(i + 1, i + 2).toUpperCase()
					+ flavour.substring(i + 2);
		}
		return flavour;
	}

	public static SwitchSession create(String flavour, InputStream is,
			OutputStream os, boolean debug, boolean showProgress) {
		try {
			return new SwitchSession(factory.get(convertFlavourName(flavour)).getInstance(), is, os);
		} catch (NullPointerException e) {
			LOG.error("Flavour " + flavour + " not found.");
			return null;
		} catch (Exception e) {
			throw new RuntimeException("Cannot create flavour " + flavour, e);
		}
	}


//	public void initialize(InputStream is, OutputStream os, boolean showProgress) {
//		this.is = is;
//		this.os = os;
//		this.expect = new Expect4j(is, os);
//	}
//
//	public void close() {
//		IOUtils.closeQuietly(is);
//		IOUtils.closeQuietly(os);
//	}

//	public Future<List<String>> start() {
//
//		return null;
//	}

//	public FromDeviceConsumer getFromDeviceConsumer() {
//		return fromDeviceConsumer;
//	}

	//public InputStream getInputStream() {
	//	return is;
	//}


//	public static List<Match> expectMatch(final StringBuilder buffer, String ...prompts) {
//		Closure closure = new Closure() {
//			public void run(ExpectState expectState) throws Exception {
//				//buffer.append(expectState.getBuffer());//string buffer for appending output of executed command
//				LOG.debug("<<"+expectState.getMatch().replaceAll("\\p{C}", "?")+"["+expectState.getBuffer().replaceAll("\\p{C}", "?")+"]");
//				buffer.append(expectState.getMatch());
//			}
//		};
//
//		List<Match> lstPattern =  new ArrayList<Match>();
//		for (String regexElement : prompts) {
//			try {
//				Match mat = new RegExpMatch(regexElement, closure);
//				lstPattern.add(mat);
//			} catch(Exception e) {
//				LOG.error("match:", e);
//			}
//		}
//		return lstPattern;
//	}



}
