package uk.org.mygrid.eobesity.csvserver.routes;

import java.io.PrintWriter;
import java.io.StringWriter;

/**
 * Defines the format for logging messages
 * 
 * @author Ian Dunlop
 * @author Stian Soiland-Reyes
 * 
 */
public class ReallySimpleFormatter extends java.util.logging.Formatter {
	@Override
	public String format(java.util.logging.LogRecord record) {
		String msg = record.getMessage() + "\n";
		StringWriter sw = new StringWriter();
		if (record.getThrown() != null) {
			record.getThrown().printStackTrace(new PrintWriter(sw));
		}
		return msg + sw;
	}

}