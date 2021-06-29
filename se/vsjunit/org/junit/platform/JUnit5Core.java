package org.junit.platform;

import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.junit.platform.engine.discovery.DiscoverySelectors.selectClass;
import static org.junit.platform.launcher.core.LauncherDiscoveryRequestBuilder.request;

import org.junit.platform.launcher.Launcher;
import org.junit.platform.launcher.LauncherDiscoveryRequest;
import org.junit.platform.launcher.core.LauncherFactory;

import org.junit.platform.JUnitTestListener;

public class JUnit5Core {

	/**
	 * Create a new <code>JUnitCore</code> to run tests.
	 */
	public JUnit5Core() {
	}

	/**
	 * Run the tests contained in the classes named in the <code>args</code>.
	 * If all tests run successfully, exit with a status of 0. Otherwise exit with a status of 1.
	 * Write feedback while tests are running and write
	 * stack traces for all failed tests after the tests all complete.
	 * @param args names of classes in which to find tests to run
	 */
	public static void runMain(String... args) {
		List<Class<?>> classes= new ArrayList<Class<?>>();  						      
        for (String each : args)
			try {
				classes.add(Class.forName(each));
			} catch (ClassNotFoundException e) {

			}

        new JUnit5Core().run(classes);
	}

    public void run(List<Class<?>> classes)
    {
		try {
            Launcher launcher = LauncherFactory.create();
			launcher.registerTestExecutionListeners(new JUnitTestListener(System.out));
			for (Class<?> testClass : classes) {
                LauncherDiscoveryRequest discoveryRequest = request().selectors(selectClass(testClass)).build();
                launcher.execute(discoveryRequest);
			}
		}
		finally {
		}
    }
}
