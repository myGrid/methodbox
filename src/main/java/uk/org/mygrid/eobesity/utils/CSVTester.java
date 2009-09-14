package uk.org.mygrid.eobesity.utils;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.Map.Entry;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import org.apache.commons.io.FileUtils;

import uk.org.mygrid.eobesity.csvserver.Messages;

import com.Ostermiller.util.CSVParser;
import com.Ostermiller.util.CSVPrinter;
import com.Ostermiller.util.LabeledCSVParser;

public class CSVTester {

	private String dbURL = "jdbc:mysql://localhost/nhsdata?user=root&password=mysqlthr@sh(r1";

	private static final String LOGGER_NAME = "org.mortbay.log"; //$NON-NLS-1$
	private static final Logger LOGGER = java.util.logging.Logger.getLogger(LOGGER_NAME);

	private boolean driverLoaded;
	private Connection dbConn;

	public CSVTester() {

	}
/**
 * 
 * @param files the list of files to add to the zip
 * @param fileName the jobID UUID
 * @return
 */
	public String zipWriter(List<File> files, String fileName) {
		byte[] buf = new byte[1024];

		String tempDirectory = Messages.getString("DownloadFile.31");

		String outFilename = null;

		try {
			// Create the ZIP file

			outFilename = tempDirectory
					+ fileName +".zip"; //$NON-NLS-1$ //$NON-NLS-2$
			ZipOutputStream out = new ZipOutputStream(new FileOutputStream(
					outFilename));

			// Compress the files

			for (File file : files) {
				FileInputStream in = new FileInputStream(file); //$NON-NLS-1$

				//remove the .UUID part and replace with '_selection.csv'
				String name = file.getName().replaceAll("." + fileName, "_selection.csv");
				
				// Add ZIP entry to output stream.
				out.putNextEntry(new ZipEntry(name)); //$NON-NLS-1$

				// Transfer bytes from the file to the ZIP file
				int len;
				while ((len = in.read(buf)) > 0) {
					out.write(buf, 0, len);
				}

				// Complete the entry
				out.closeEntry();
				in.close();
			}

			// Complete the ZIP file
			out.close();
			//remove the old files since they are now inside the zip
			for (File file:files) {
				FileUtils.forceDelete(file)	;			
			}
		} catch (IOException e) {
		}
		return outFilename;
	}

	/**
	 * Given a dataset name and a Map of the variables to their values write out
	 * a CSV file with these values in it
	 * 
	 * @param dataset
	 *            the name os a dataset
	 * @param valueMap
	 *            the values for each of the variables
	 * @return the CSV file written out to disk
	 */
	public File CSVWriter(String dataset, Map<String, List<String>> valueMap, String jobID) {

		String tempDirectory = Messages.getString("DownloadFile.31"); //$NON-NLS-1$

		File file = null;
//		Set<Entry<String, List<String>>> valueMapSet = valueMap.entrySet();
//		for (Entry<String, List<String>> entry : valueMapSet) {
			// the dataset name

			file = new File(tempDirectory + dataset + "." +jobID); //$NON-NLS-1$
			FileOutputStream outputStream = null;
			try {
				outputStream = new FileOutputStream(file);
			} catch (FileNotFoundException e1) {
				e1.printStackTrace();
			}

			CSVPrinter csvPrinter = new CSVPrinter(outputStream);
			csvPrinter.changeDelimiter('\t');

//			Set<Entry<String, List<String>>> entrySet = valueMap.entrySet();

			Set<String> keySet = valueMap.keySet();

			int numberOfVariables = keySet.size();
			// get the names of the columns and write to the CSV
			String[] varKeys = new String[numberOfVariables];
			keySet.toArray(varKeys);

			try {
				csvPrinter.writeln(varKeys);
			} catch (IOException e1) {
				e1.printStackTrace();
			}
			valueMap.get(varKeys[0]).size();
			// the number of values for the variables in this dataset
			int size = valueMap.get(varKeys[0]).size();
			// get each value from each variable and keep building up a line of
			// values
			for (int i = 0; i < size; i++) {
				List<String> valueLineList = new ArrayList<String>();
				for (String key : keySet) {
					valueLineList.add(valueMap.get(key).get(i));
				}
				String[] valueLineArray = new String[keySet.size()];
				valueLineList.toArray(valueLineArray);
				try {
//					java.util.logging.Logger.getLogger(LOGGER_NAME).log(Level.INFO,
//							"Writing line- " + i);
					csvPrinter.writeln(valueLineArray);
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}

			try {
				csvPrinter.flush();
				csvPrinter.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
//		}
		return file;
	}

	/**
	 * Uses {@link LabeledCSVParser} to parse a CSV type file which has the
	 * column names at the top
	 * 
	 * @param file
	 * @return
	 * @throws FileNotFoundException
	 */
	public Map<String, List<String>> readFieldNames(String dataset,
			List<String> variables) throws FileNotFoundException {

		Map<String, List<String>> varMap = new HashMap<String, List<String>>();

		String directory = Messages.getString("RTFSearcher.0");

		// stop people from requesting any file
		File rootDirectory = new File(directory);
		String[] list = rootDirectory.list();
		List<String> asList2 = Arrays.asList(list);
		if (!asList2.contains(dataset)) {
			throw new FileNotFoundException("Dataset " + dataset
					+ "does not exist");
		}

		File file = new File(directory + dataset);

		// Connection connection =
		// ObeDBConnection.getInstance().getConnection();
		// try {
		// connection.setAutoCommit(false);
		// connection.setCatalog(catalog);
		// } catch (SQLException e4) {
		// // TODO Auto-generated catch block
		// e4.printStackTrace();
		// }
		// try {
		// Statement createStatement = connection.createStatement();
		// createStatement.execute("START TRANSACTION");
		// } catch (SQLException e4) {
		// // TODO Auto-generated catch block
		// e4.printStackTrace();
		// }

		// Statement insertValue = null;
		// try {
		// insertValue = connection.createStatement();
		// } catch (SQLException e3) {
		// // TODO Auto-generated catch block
		// e3.printStackTrace();
		// }

		// PreparedStatement getVariable = null;
		// try {
		// getVariable = connection
		// .prepareStatement("select * from Variables where name=? and survey_id=?");
		// } catch (SQLException e3) {
		// // TODO Auto-generated catch block
		// e3.printStackTrace();
		// }

		// try {
		// insertVariableValue = connection
		// .prepareStatement("insert into ? values (?,?)");
		// } catch (SQLException e3) {
		// // TODO Auto-generated catch block
		// e3.printStackTrace();
		// }

		BufferedInputStream bufferedInputStream = null;
		try {
			bufferedInputStream = new BufferedInputStream(new FileInputStream(
					file));
		} catch (FileNotFoundException e1) {
			e1.printStackTrace();
		}

		CSVParser parser = new CSVParser(bufferedInputStream, '\t');

		LabeledCSVParser labelParser = null;
		try {
			labelParser = new LabeledCSVParser(parser);
		} catch (IOException e) {
			e.printStackTrace();
		}
		String[] labels = null;
		try {
			labels = labelParser.getLabels();
		} catch (IOException e) {
			e.printStackTrace();
		}
		List<String> asList = Arrays.asList(labels);

		// create a table for every variable
		// for (String label : asList) {
		// try {
		// PreparedStatement createTable = connection
		// .prepareStatement("Create table " + label
		// + " (value VARCHAR(20),position INT)");
		// createTable.execute();
		// System.out.println("Created table: " + label);
		// } catch (SQLException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
		// }
		//
		// try {
		// connection.commit();
		// } catch (SQLException e1) {
		// // TODO Auto-generated catch block
		// e1.printStackTrace();
		// }

		// try {
		// connection.setAutoCommit(false);
		// Statement createStatement = connection.createStatement();
		// createStatement.execute("START TRANSACTION");
		// } catch (SQLException e4) {
		// // TODO Auto-generated catch block
		// e4.printStackTrace();
		// }

		String[] parseLine;
		// for (String varLabel:asList) {
		try {
			// int i = 0;
			boolean first = true;
			while ((parseLine = labelParser.getLine()) != null) {
//				java.util.logging.Logger.getLogger(LOGGER_NAME).log(Level.INFO,
//						"Processing- " + labelParser.lastLineNumber());

				// System.out.println("Line: " + labelParser.lastLineNumber());
				for (String varLabel : variables) {
					// check to see if the metadata case matches the header
					// first time round
					if (first) {
						if (asList.contains(varLabel.toLowerCase())) {
							variables.set(variables.indexOf(varLabel), varLabel
									.toLowerCase());
							varLabel = varLabel.toLowerCase();
						} else {
							variables.set(variables.indexOf(varLabel), varLabel
									.toUpperCase());
							varLabel = varLabel.toUpperCase();
						}
					}

					List<String> valueList = varMap.get(varLabel);
					if (valueList == null) {
						valueList = new ArrayList<String>();
						varMap.put(varLabel, valueList);
					}
					valueList.add(labelParser.getValueByLabel(varLabel));
					// Integer varID = varMap.get(varLabel);
					// if (varID == null) {
					// getVariable.setString(1, varLabel);
					// getVariable.setInt(2, surveyID);
					// getVariable.execute();
					// ResultSet resultSet = getVariable.getResultSet();
					// while (resultSet.next()) {
					// varID = resultSet.getInt("id");
					// }
					// varMap.put(varLabel, varID);
					// }
					// String sql = "insert into " + varLabel
					// + " values (\'" + labelParser
					// .getValueByLabel(varLabel)+ "\'," +
					// labelParser.lastLineNumber() +")";
					//					
					// // PreparedStatement insertVariableValue = connection
					// // .prepareStatement("insert into " + varLabel
					// // + " values (?,?)");
					// // // insertVariableValue.setString(1, varLabel);
					// // insertVariableValue.setString(1, labelParser
					// // .getValueByLabel(varLabel));
					// // insertVariableValue.setInt(2,
					// labelParser.lastLineNumber());
					// // // insertVariableValue.setInt(3, varID);
					// // insertVariableValue.executeUpdate();
					// // insertVariableValue = null;
					// insertValue.execute(sql);

				}
				// i++;
				// if (i == 50) {
				// connection.commit();
				// i = 0;
				// }
				first = false;
			}
		} catch (IOException e2) {
			// TODO Auto-generated catch block
			e2.printStackTrace();

		}
		// try {
		// // getVariable.close();
		// // insertVariableValue.close();
		// connection.commit();
		// } catch (SQLException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
		// }
		// try {
		// String[] line = labelParser.getLine();
		// } catch (IOException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
		//
		// String parseVal;
		// try {
		// while ((parseVal = parser.nextValue()) != null) {
		// fieldNames.add(parseVal);
		//
		// }
		// } catch (IOException e1) {
		// logger.warn(e1);
		// }
		return varMap;

	}

	/**
	 * Read the data values from a CSV file which has a fixed number of values
	 * per database row
	 * 
	 * @param file
	 *            The CSV data
	 * @param fieldNumber
	 *            The number of columns in the table row
	 */
	private void readValues(String tableName, File file, int fieldNumber,
			List<String> fieldNames, int startNumber, int finishNumber) {

		// store the parsed float value against the field name
		Map<String, Float> floatMap = new HashMap<String, Float>();

		// store the parsed string value against the field name
		Map<String, String> stringMap = new HashMap<String, String>();

		List<Float> floatValues = new ArrayList<Float>();

		List<String> stringValues = new ArrayList<String>();

		int upTo = 0;

		int totalField = 0;

		BufferedInputStream bufferedInputStream = null;
		try {
			bufferedInputStream = new BufferedInputStream(new FileInputStream(
					file));
		} catch (FileNotFoundException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}

		CSVParser parser = new CSVParser(bufferedInputStream, '\t');

		String parseVal;
		try {
			while ((parseVal = parser.nextValue()) != null) {

				Float value;
				try {
					value = Float.parseFloat(parseVal);
					floatValues.add(value);
					floatMap.put(fieldNames.get(totalField), value);
					totalField++;
					upTo++;

				} catch (Exception e) {
					// // null value
					// if (parseVal != null) {
					// // probably a string
					// stringValues.add(parseVal);
					// stringMap.put(fieldNames.get(totalField), parseVal);
					// totalField++;
					// upTo++;
					// } else {
					// TODO not sure if it is a float or string yet, could
					// make a
					// guess using the description file, see RTFSearcher
					floatValues.add(null);
					floatMap.put(fieldNames.get(totalField), null);
					totalField++;
					upTo++;
					// }
					// System.out.println("null");
					continue;
				}

				if (upTo == fieldNumber) {
					writeDBLine(tableName, fieldNames, floatValues,
							startNumber, finishNumber);
					upTo = 0;
					totalField = 0;
					floatMap.clear();
					stringMap.clear();
					floatValues.clear();
				}
				// System.out.println(parseVal);

			}
		} catch (IOException e1) {
//			 logger.warn(e1);
		}

		// CSVReader reader = null;
		// try {
		// reader = new CSVReader(new FileReader(file.toString()), '\t');
		// } catch (FileNotFoundException e) {
		// logger.warn(e);
		// }
		//
		//		
		// try {
		//			
		// while ((line = reader.readNext()) != null) {
		// for (String stuff : line) {
		// Float value;
		// try {
		// value = Float.parseFloat(stuff);
		// values.add(value);
		// upTo++;
		//						
		// } catch (Exception e) {
		// // should be a field name
		// fieldNames.add(stuff);
		// continue;
		// }
		// // first time round write out the table
		// if (!fieldsRead) {
		// fieldSize = fieldNames.size();
		// writeTable(fieldNames, file.getName());
		// fieldsRead = true;
		// }
		// if (upTo == fieldSize) {
		// writeDBLine(fieldNames, values);
		// upTo = 0;
		// values.clear();
		// }
		// System.out.println(stuff);
		// }
		// }
		// // reader.readNext();
		// //
		// // List readAll = reader.readAll();
		// } catch (IOException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }

	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {

		// CSVTester tester = new CSVTester();
		// File file = new File("/Users/Ian/scratch/1991-1992.csv");
		// tester.readFieldNames(file);

		// FileInputStream fstream = null;
		// try {
		// fstream = new FileInputStream(
		//					"/Volumes/Data/obesity_data/2002/HSE2002.tab"); //$NON-NLS-1$ //$NON-NLS-2$
		// } catch (FileNotFoundException e) {
		// e.printStackTrace();
		// }
		// String directory = Messages.getString("RTFSearcher.0");
		// String year = "2002";
		// CSVTester tester = new CSVTester();
		// File file = new File(directory + "/" + year + "/HSE" + year +
		// ".tab");
		// List<String> labelList = new ArrayList<String>();
		// labelList.add("CHILD_WT");
		// tester.readFieldNames(file, "HSE" + year, null);

		// BufferedReader reader = new BufferedReader(new InputStreamReader(
		// fstream));
		// String line;
		// String xmlDoc = null;
		// try {
		// while ((line = reader.readLine()) != null) {
		// xmlDoc = xmlDoc + line;
		// }
		// } catch (IOException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
		// try {
		// JSONObject jsonObject = XML.toJSONObject(xmlDoc);
		// String jsonString = jsonObject.toString();
		// BufferedWriter out = new BufferedWriter(new FileWriter(
		// "/Users/Ian/scratch/json.js"));
		// out.write(jsonString);
		// out.close();
		//
		// } catch (JSONException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
		// // read all the field names
		// // List<String> readFieldNames = tester.readFieldNames(file);
		// // String name = file.getName();
		// // String replace = name.replace(".", "_");
		// // tester.writeTable(readFieldNames, "HSE2002");
		// // File file2 = new
		// File("/Users/Ian/obesity_data/2002/2002-data.tab");
		// // tester.writeSmallTables(file2, readFieldNames, "HSE2002");
		// catch (FileNotFoundException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// } catch (IOException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }

		// file = new File("/Users/Ian/obesity_data/1993/1993-headers.tab");
		// readFieldNames = tester.readFieldNames(file);
		// // name = file.getName();
		// // replace = name.replace(".", "_");
		// tester.writeTable(readFieldNames, "HSE1993");
		//		
		// file = new File("/Users/Ian/obesity_data/1994/1994-headers.tab");
		// readFieldNames = tester.readFieldNames(file);
		// // name = file.getName();
		// // replace = name.replace(".", "_");
		// tester.writeTable(readFieldNames, "HSE1994");

	}

	private void getMetadata() {
		Connection connection = getConnection();
		DatabaseMetaData metaData;
		try {

			PreparedStatement ps = connection
					.prepareStatement("SELECT * FROM NHS");
			ResultSetMetaData rsmd = ps.getMetaData();

			int ncols = rsmd.getColumnCount();
			String[] names = new String[ncols];
			for (int i = 0; i < ncols; i++) {
				names[i] = rsmd.getColumnName(i + 1);
				String substring = names[i].substring(0, names[i].length() - 1);
				System.out.println(substring);
			}
			dbConn.close();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

	/**
	 * Create the database table
	 * 
	 * @param fieldNames
	 * @param tableName
	 */
	private void writeTable(List<String> fieldNames, String tableName) {

		String sql_fields = new String();
		String finalField = fieldNames.get(fieldNames.size() - 1);

		for (String fieldName : fieldNames) {
			if (fieldName.equals(finalField)) {
				fieldName = fieldName + "_";
				sql_fields = sql_fields + fieldName + " TINYINT)";
			} else {
				fieldName = fieldName + "_";
				sql_fields = sql_fields + fieldName + " TINYINT, ";
			}
		}
		String create_db = "CREATE TABLE " + tableName + "(" + sql_fields;

		try {
			Statement statement = getConnection().createStatement();
			statement.executeUpdate(create_db);
		} catch (SQLException e) {
//			logger.warn(e);
		}

	}

	/**
	 * Split a table with too many columns into "more" manageable 500 column
	 * chunks
	 * 
	 * @param fieldNames
	 * @param tableName
	 */
	private void writeSmallTables(File file, List<String> fieldNames,
			String tableName) {
		// how many variables in each table
		List<Integer> dbTableList = new ArrayList<Integer>();
		// the SQL to create each table
		List<String> dbSQLList = new ArrayList<String>();

		List<String> tableNames = new ArrayList<String>();

		String finalField = fieldNames.get(fieldNames.size() - 1);
		int a = 0;
		int x = 501;
		int tableNum = 0;
		int size = fieldNames.size();
		boolean finished = false;
		while (x <= size) {
			String sql_fields = new String();
			dbTableList.add(x);
			for (int i = a; i < x; i++) {
				String fieldName = fieldNames.get(i);
				if (i == (x - 1)) {
					fieldName = fieldName + "_";
					sql_fields = sql_fields + fieldName + " FLOAT)";
				} else {
					fieldName = fieldName + "_";
					sql_fields = sql_fields + fieldName + " FLOAT, ";
				}
			}
			String o = tableName + "_" + tableNum;
			sql_fields = "CREATE TABLE " + o + "(" + sql_fields;
			tableNames.add(o);
			dbSQLList.add(sql_fields);
			tableNum++;
			a = x;
			x = x + 500;
			if (x > size && !finished) {
				x = fieldNames.size();
				finished = true;
			}
		}

		// for (String fieldName : fieldNames) {
		// if (fieldName.equals(finalField)) {
		// fieldName = fieldName + "_";
		// sql_fields = sql_fields + fieldName + " TINYINT)";
		// } else {
		// fieldName = fieldName + "_";
		// sql_fields = sql_fields + fieldName + " TINYINT, ";
		// }
		// }
		// String create_db = "CREATE TABLE " + tableName + "(" + sql_fields;
		//
		// create the tables
		try {
			for (String val : dbSQLList) {
				Statement statement = getConnection().createStatement();
				statement.executeUpdate(val);
			}
		} catch (SQLException e) {
//			logger.warn(e);
		}

		writeSmallDataset(file, fieldNames, dbTableList, tableNames);

	}

	public void writeSmallDataset(File file, List<String> fieldNames,
			List<Integer> dbTableList, List<String> tableNames) {
		int fin = 500;
		int start = 0;
		for (int i = 0; i < dbTableList.size(); i++) {
			readValues(tableNames.get(i), file, fieldNames.size(), fieldNames,
					start, fin);
			start = fin + 1;
			fin = fin + 500;
			if ((i == (dbTableList.size() - 2))) {
				fin = dbTableList.get(i + 1) - 1;
			}
		}
	}

	/**
	 * Add one line to the database table
	 * 
	 * @param fieldNames
	 * @param values
	 * @param finishNumber
	 * @param startNumber
	 */
	private void writeDBLine(String tableName, List<String> fieldNames,
			List<Float> values, int startNumber, int finishNumber) {
		String sql_fields = new String();
		String finalField = fieldNames.get(fieldNames.size() - 1);
		List<Float> floatList = new ArrayList<Float>();

		for (int i = startNumber; i < finishNumber + 1; i++) {
			if (i == (finishNumber)) {
				sql_fields = sql_fields + fieldNames.get(i) + "_";
			} else {
				sql_fields = sql_fields + fieldNames.get(i) + "_, ";

			}
		}

		String sql_values = new String();

		for (int i = startNumber; i < finishNumber + 1; i++) {
			Float float1 = values.get(i);
			if (i == (finishNumber)) {
				if (float1 == null) {
					floatList.add(float1);
					sql_values = sql_values + "NULL ";
				} else {
					floatList.add(float1);
					sql_values = sql_values + " " + float1;
				}
			} else {
				if (float1 == null) {
					floatList.add(float1);
					sql_values = sql_values + " NULL,";
				} else {
					floatList.add(float1);
					sql_values = sql_values + " " + float1 + ",";
				}

			}
		}

		// for (String fieldName : fieldNames) {
		// if (fieldName.equals(finalField)) {
		// sql_fields = sql_fields + fieldName + "_";
		// } else {
		// sql_fields = sql_fields + fieldName + "_, ";
		// }
		// }
		//
		// String sql_values = new String();
		//
		// for (int i = 0; i < values.size(); i++) {
		// Float float1 = values.get(i);
		// if (i == values.size() - 1) {
		// if (float1 == null) {
		// sql_values = sql_values + "NULL ";
		// } else {
		// sql_values = sql_values + " " + float1;
		// }
		// } else {
		// if (float1 == null) {
		// sql_values = sql_values + " NULL,";
		// } else {
		// sql_values = sql_values + " " + float1 + ",";
		// }
		//
		// }
		// }

		// for (Float fl : values) {
		// try {
		// sql_values = sql_values + "\'" + Float.toString(fl) + "\'";
		// } catch (Exception e) {
		// logger.warn(e);
		// }
		// }

		String sql = "INSERT INTO " + tableName + " (" + sql_fields
				+ ") VALUES (" + sql_values + ")";

		try {
			Statement statement = getConnection().createStatement();
			statement.executeUpdate(sql);
		} catch (SQLException e) {
//			logger.warn(e);
		}
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

	private void loadDriver() {
		try {
			getClass().getClassLoader().loadClass("com.mysql.jdbc.Driver")
					.newInstance();
		} catch (InstantiationException e) {
//			logger.warn(e);
		} catch (IllegalAccessException e) {
//			logger.warn(e);
		} catch (ClassNotFoundException e) {
//			logger.warn(e);
		}
		driverLoaded = true;
	}

	public void openConnection() {
		try {
			dbConn = DriverManager.getConnection(dbURL);
			dbConn.setAutoCommit(true);
		} catch (SQLException e) {
//			logger.warn(e);
		}
	}

}
