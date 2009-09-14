package uk.org.mygrid.eobesity.utils;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import org.apache.log4j.Logger;

import uk.org.mygrid.eobesity.csvserver.Messages;

public class ObeDBConnection {
	//TODO get this from external file
	private static String dbURL = Messages.getString("DBConnection.3"); //$NON-NLS-1$
	
	private Connection dbConn;
	
	private static ObeDBConnection dbConnection;
	
	private boolean driverLoaded = false;
	
	private static Logger logger = Logger.getLogger(ObeDBConnection.class);

	private String catalog;
	
	private ObeDBConnection() {
		
	}
	
	public static ObeDBConnection getInstance(){
		if (dbConnection == null) {
			dbConnection = new ObeDBConnection();
		}
		return dbConnection;
	}
	
	public synchronized Connection getConnection() {
		if (!driverLoaded) {
			loadDriver();
		}

		if (dbConn == null) {
			openConnection();
		}
		return dbConn;
	}
	
	private void openConnection() {
		try {
			dbConn = DriverManager.getConnection(dbURL);
			dbConn.setAutoCommit(true);
		} catch (SQLException e) {
			logger.warn(e);
		}
	}
	
	private void loadDriver() {
		try {
			getClass().getClassLoader().loadClass(
					"com.mysql.jdbc.Driver").newInstance(); //$NON-NLS-1$
		} catch (InstantiationException e) {
			logger.warn(e);
		} catch (IllegalAccessException e) {
			logger.warn(e);
		} catch (ClassNotFoundException e) {
			logger.warn(e);
		}
		driverLoaded = true;
	}

}
