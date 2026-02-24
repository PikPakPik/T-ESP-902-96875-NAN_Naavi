package fr.naavi.core.utils;

import java.io.PrintWriter;
import java.io.StringWriter;

/**
 * Utility for exception formatting, used for logging and Seq/GELF compatibility.
 */
public final class ExceptionUtils {

    private ExceptionUtils() {
    }

    /**
     * Formats the stack trace of a throwable as a string.
     * Used so GELF full_message contains the stack trace, which seq-input-gelf maps to @x (Exception).
     *
     * @param t the throwable
     * @return the formatted stack trace, or empty string if null
     */
    public static String formatStackTrace(Throwable t) {
        if (t == null) {
            return "";
        }
        StringWriter sw = new StringWriter();
        t.printStackTrace(new PrintWriter(sw));
        return sw.toString();
    }
}
