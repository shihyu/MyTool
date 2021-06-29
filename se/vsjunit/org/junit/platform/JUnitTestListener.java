package org.junit.platform;

import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import org.junit.platform.commons.util.ExceptionUtils;
import org.junit.platform.engine.TestExecutionResult;
import org.junit.platform.engine.TestSource;
import org.junit.platform.engine.support.descriptor.PackageSource;
import org.junit.platform.engine.support.descriptor.ClassSource;
import org.junit.platform.engine.support.descriptor.MethodSource;
import org.junit.platform.launcher.TestExecutionListener;
import org.junit.platform.launcher.TestIdentifier;
import org.junit.platform.launcher.TestPlan;

final class JUnitTestListener implements TestExecutionListener {

    private class JUFailure {
        private final String m_description;
        private final Throwable m_throwable;

        JUFailure(String description, Throwable throwable) {
            this.m_description = description;
            this.m_throwable = throwable;
        }

        public String description() {
            return m_description;
        }

        public Throwable throwable() {
            return m_throwable;
        }
    }

    private final PrintStream fWriter;
	private Optional<TestPlan> testPlan = Optional.empty();
    private List<JUFailure> failures;
    private int num_tests = 0;

    public JUnitTestListener(PrintStream writer) {
        this.fWriter = writer;
        failures = new ArrayList<JUFailure>();
    }

    @Override
	public void testPlanExecutionStarted(TestPlan testPlan) {
		this.testPlan = Optional.of(testPlan);
        num_tests = 0;
	}

	@Override
	public void testPlanExecutionFinished(TestPlan testPlan) {
		this.testPlan = Optional.empty();
        fWriter.println();
        printFailures();
        printFooter();
	}

	@Override
	public void executionStarted(TestIdentifier testIdentifier) {
		if (testIdentifier.isTest()) {
            TestSource testSource = testIdentifier.getSource().orElse(null);
            if (testSource instanceof MethodSource) {
                String test_class = ((MethodSource) testSource).getClassName();
                String test_method = ((MethodSource) testSource).getMethodName();

                fWriter.print("METHOD " + test_method + "(" + test_class+ ") .");
                ++num_tests;
            }
        }
	}

	@Override
	public void executionSkipped(TestIdentifier testIdentifier, String reason) {
        if (testIdentifier.isTest()) {
            TestSource testSource = testIdentifier.getSource().orElse(null);
            if (testSource instanceof MethodSource) {
                String test_class = ((MethodSource) testSource).getClassName();
                String test_method = ((MethodSource) testSource).getMethodName();

                fWriter.print("METHOD " + test_method + "(" + test_class + ") .I");
            }
        }
	}

	@Override
	public void executionFinished(TestIdentifier testIdentifier, TestExecutionResult testExecutionResult) {
        if (testIdentifier.isTest()) {
            TestSource testSource = testIdentifier.getSource().orElse(null);
            if (testSource instanceof MethodSource) {
                if (testExecutionResult.getStatus() == TestExecutionResult.Status.ABORTED) {
                    fWriter.println();
                    fWriter.println("ABORTED");

                } else if (testExecutionResult.getStatus() == TestExecutionResult.Status.FAILED) {
                    fWriter.append('E'); 
                    fWriter.println();
                    testExecutionResult.getThrowable().ifPresent(t -> addException(testIdentifier, t));

                } else {
                    fWriter.println();
                }
            }
		}
	}

    protected void addException(TestIdentifier testIdentifier, Throwable throwable) {
        TestSource testSource = testIdentifier.getSource().orElse(null);
        if (testSource instanceof MethodSource) {
            String test_class = ((MethodSource) testSource).getClassName();
            String test_method = ((MethodSource) testSource).getMethodName();
            failures.add(new JUFailure(test_method + "(" + test_class + ")", throwable));
        }
    }

	protected void printFailures() {
        int num_failures = failures.size();
		if (num_failures == 0)
			return;

		if (num_failures == 1)
			fWriter.println("There was " + num_failures + " failure:");
		else
			fWriter.println("There were " + num_failures + " failures:");

        int i = 1;
        for (JUFailure f : failures)
			printFailure(f, "" + i++);
	}

    protected void printFailure(JUFailure f, String prefix) {
		fWriter.println(prefix + ") " + f.description());
        fWriter.println(ExceptionUtils.readStackTrace(f.throwable()));
	}

    protected void printFooter() {
        int num_failures = failures.size();
        if (num_failures == 0) {
            fWriter.println();
            fWriter.print("OK");
            fWriter.println(" (" + num_tests + " test" + (num_tests == 1 ? "" : "s") + ")");

        } else {
            fWriter.println();
            fWriter.println("FAILURES!!!");
            fWriter.println("Tests run: " + num_tests + ",  Failures: " + num_failures);
        }
        fWriter.println();
    }

}




