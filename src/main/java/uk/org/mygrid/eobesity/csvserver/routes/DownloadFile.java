package uk.org.mygrid.eobesity.csvserver.routes;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.Map.Entry;
import java.util.logging.Level;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.restlet.Context;
import org.restlet.data.MediaType;
import org.restlet.data.Request;
import org.restlet.data.Response;
import org.restlet.data.Status;
import org.restlet.resource.DomRepresentation;
import org.restlet.resource.Representation;
import org.restlet.resource.Resource;
import org.restlet.resource.Variant;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

import uk.org.mygrid.eobesity.csvserver.Messages;
import uk.org.mygrid.eobesity.utils.CSVTester;

/**
 * Create a Zip file with CSV data for each of the datasets and variables
 * requested. The request is in the style of: <code>
 * <request>
 * <Datasets>
 * <Dataset name="HSE2002">
 * <Variables>
 * <Variable>age</Variable><Variable>year</Variable><Variable>dobmonth</Variable>
 * </Variables>
 * </Dataset>
 * <Dataset name="HSE2003">
 * <Variables>
 * <Variable>height</Variable>
 * </Variables>
 * </Dataset>
 * <Dataset year="HSE2006">
 * <Variables>
 * <Variable>bmi</Variable>
 * </Variables>
 * </Dataset>
 * </Datasets>
 * </request>
 * </code>
 * 
 * @author Ian Dunlop
 * 
 */
public class DownloadFile extends Resource {

	/** Date used in the name of the zip file */
	public static final String DATE_FORMAT_NOW = "yyyy-MM-dd HH:mm:ss"; //$NON-NLS-1$

	// Map of UUIDs to whether complete or not
	private static Map<String, Boolean> completedJobList = new HashMap<String, Boolean>();

	private static Map<String, String> numberProcessed = new HashMap<String, String>();
	
	private static List<String> failedJobs = new ArrayList<String>();

	/**
	 * Map of dataset name to List containing {@link Variable}s
	 */
	// private Map<String, List<String>> datasetToVariableMap;
	public DownloadFile(Context context, Request request, Response response) {
		super(context, request, response);
		getVariants().add(new Variant(MediaType.TEXT_XML));
	}

	public DownloadFile() {
		
	}

	@Override
	public boolean allowPost() {
		return true;
	}

	/**
	 * Get the values sent in the request, parse for the concepts and the
	 * variables required in the returned CSV files. Return the CSVs inside a
	 * zip, one file for each dataset requested
	 */
	@Override
	public void post(final Representation entity) {
		super.post(entity);

		try {

			// FileRepresentation fileRep = new FileRepresentation(file,
			// MediaType.TEXT_PLAIN, 12345);

			DomRepresentation representation = new DomRepresentation(
					MediaType.TEXT_XML);
			Document d = representation.getDocument();
			Element jobIDElement = d.createElement("jobid");
			final String jobID = UUID.randomUUID().toString();
			jobIDElement.appendChild(d.createTextNode(jobID));
			d.appendChild(jobIDElement);
			d.normalizeDocument();
			getResponse().setEntity(d);

			// run the csv creation in a separate thread
			createNewThread(jobID, entity.getStream()).start();

			getResponse().setEntity(representation);
			getResponse().setStatus(Status.SUCCESS_OK);

		} catch (FileNotFoundException e) {
			getResponse().setStatus(Status.CLIENT_ERROR_BAD_REQUEST);
		} catch (IOException e) {
			getResponse().setStatus(Status.SERVER_ERROR_INTERNAL);
		}

	}

	public static void setCompletedJobList(Map<String, Boolean> completedJobList) {
		DownloadFile.completedJobList = completedJobList;
	}

	public static synchronized Map<String, Boolean> getCompletedJobList() {
		return completedJobList;
	}

	public static synchronized Map<String, String> getNumberProcessed() {
		return numberProcessed;
	}

	private synchronized void writeJobState() {
		String serializeDirectory = Messages.getString("SerializeMap.0");
		File file = new File(serializeDirectory + "jobMap");
		try {
			FileOutputStream stream = new FileOutputStream(file);
			ObjectOutputStream objectStream = new ObjectOutputStream(stream);
			objectStream.writeObject(getCompletedJobList());
			objectStream.close();
		} catch (FileNotFoundException e) {
			getLogger().log(Level.INFO, "Problem serializing job map");
		} catch (IOException e) {
			getLogger().log(Level.INFO, "Problem serializing job map");
		}
	}

	private void writeDatasetMap(String uuid,
			Map<String, List<String>> datasetToVariableMap) {
		String serializeDirectory = Messages.getString("SerializeMap.0");
		File file = new File(serializeDirectory + uuid + ".variableMap");
		try {
			FileOutputStream stream = new FileOutputStream(file);
			ObjectOutputStream objectStream = new ObjectOutputStream(stream);
			objectStream.writeObject(datasetToVariableMap);
			objectStream.close();
		} catch (FileNotFoundException e) {
			getLogger().log(Level.INFO, "Problem serializing dataset map");
		} catch (IOException e) {
			getLogger().log(Level.INFO, "Problem serializing dataset map");
		}
	}
	
	public Thread createNewThread(final String jobID, final InputStream stream) {
		Thread thread = new Thread(new Runnable() {

			public void run() {
				try {
					getCompletedJobList().put(jobID, false);
					writeJobState();
					Map<String, List<String>> datasetToVariableMap = new HashMap<String, List<String>>();

					DocumentBuilderFactory factory = DocumentBuilderFactory
							.newInstance();

					// Now use the factory to create a DOM parser (a.k.a. a
					// DocumentBuilder)
					DocumentBuilder parser = null;
					try {
						parser = factory.newDocumentBuilder();
					} catch (ParserConfigurationException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}

					// Parse the file and build a Document tree to represent
					// its content
					Document xmlDoc = null;
					try {
						xmlDoc = parser.parse(stream);
					} catch (SAXException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}

					XPathFactory xpFactory = XPathFactory.newInstance();
					XPath xpath = xpFactory.newXPath();

					String query = "//Dataset"; //$NON-NLS-1$
					XPathExpression expr = null;
					try {
						expr = xpath.compile(query);
					} catch (XPathExpressionException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
					NodeList conceptNodes = null;
					try {
						conceptNodes = (NodeList) expr.evaluate(xmlDoc,
								XPathConstants.NODESET);
					} catch (XPathExpressionException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}

					for (int m = 0; m < conceptNodes.getLength(); m++) {
						Node conceptNode = conceptNodes.item(m);
						NamedNodeMap attributes = conceptNode
								.getAttributes();

						//			Node nameItem = attributes.getNamedItem("name"); //$NON-NLS-1$
						// year is actually the dataset name
						Node datasetName = attributes.getNamedItem("name"); //$NON-NLS-1$
						// String name = nameItem.getNodeValue();
						String year = datasetName.getNodeValue();
						List<String> variableList = new ArrayList<String>();
						// check if the dataset exists in the map
						if (!datasetToVariableMap.containsKey(year)) {
							datasetToVariableMap.put(year, variableList);
						}

						NodeList childNodes = conceptNode.getChildNodes();
						for (int k = 0; k < childNodes.getLength(); k++) {
							// Variables node
							Node variablesNode = childNodes.item(k);
							// Variable nodes
							NodeList variableNodeList = variablesNode
									.getChildNodes();
							for (int j = 0; j < variableNodeList
									.getLength(); j++) {
								Node variableNode = variableNodeList
										.item(j);
								// the child could be blank space so check
								// if it is an
								// element before proceeding
								if (variableNode instanceof Element) {
									String varName = ((Element) variableNode)
											.getFirstChild().getNodeValue();
									// add it to the map
									datasetToVariableMap.get(year).add(
											varName);
								}
							}

						}
					}
					// we now have a map of all the variables so write it
					// out in case of any server problems

					writeDatasetMap(jobID, datasetToVariableMap);

					Set<Entry<String, List<String>>> entrySet = datasetToVariableMap
							.entrySet();
					List<File> fileList = new ArrayList<File>();
					CSVTester csvTester = new CSVTester();
					int totalDatasets = datasetToVariableMap.keySet()
							.size();
					int currentDataset = 0;
					for (Entry<String, List<String>> entry : entrySet) {
						Map<String, List<String>> readFieldNames;
						try {
							String key = entry.getKey();
							List<String> value = entry.getValue();
							getLogger().log(Level.INFO,
									"Loading data- " + key + ": " + value);
							currentDataset++;
							getNumberProcessed().put(
									jobID,
									"Processing dataset " + currentDataset
											+ " of " + totalDatasets);
							readFieldNames = csvTester.readFieldNames(key,
									value);
							getNumberProcessed().put(
									jobID,
									"Writing dataset " + currentDataset
											+ " of " + totalDatasets);
							getLogger().log(Level.INFO,
									"Creating file- " + key + ": " + value);
							File csvWriter = csvTester.CSVWriter(entry
									.getKey(), readFieldNames, jobID);
							fileList.add(csvWriter);
						} catch (FileNotFoundException e) {
							throw e;
						}
					}
					getLogger().log(Level.INFO,
							"Adding files to zip- " + fileList);
					getNumberProcessed().put(jobID, "Creating zip file");
					csvTester.zipWriter(fileList, jobID);

					getCompletedJobList().put(jobID, true);
					writeJobState();
					getLogger().log(Level.INFO,
							getCompletedJobList().toString());
				} catch (FileNotFoundException e) {
					// TODO need to log this error somewhere, maybe write it
					// out to the
					// file that the user gets
				}
			}

		});
		return thread;
	}

	public static void setFailedJobs(List<String> failedJobs) {
		DownloadFile.failedJobs = failedJobs;
	}

	public static List<String> getFailedJobs() {
		return failedJobs;
	}


	// /**
	// * Query the database for the variables required. Write out a CSV file for
	// * each dataset with the variables as column headers and values below.
	// * Delimit by tab with a new line at the end. Add the CSV files to a Zip
	// * file, save it to disk and return the file name
	// *
	// * @param xmlDoc
	// * @return
	// * @throws FileNotFoundException
	// */
	// private String createCSVFile(
	// Map<String, List<String>> datasetToVariableMap, String jobID)
	// throws FileNotFoundException {
	//
	// Set<Entry<String, List<String>>> entrySet = datasetToVariableMap
	// .entrySet();
	// List<File> fileList = new ArrayList<File>();
	// CSVTester csvTester = new CSVTester();
	//
	// for (Entry<String, List<String>> entry : entrySet) {
	// Map<String, List<String>> readFieldNames;
	// try {
	// String key = entry.getKey();
	// List<String> value = entry.getValue();
	// getLogger().log(Level.INFO,
	// "Loading data- " + key + ": " + value);
	// readFieldNames = csvTester.readFieldNames(key, value);
	// getLogger().log(Level.INFO,
	// "Creating file- " + key + ": " + value);
	// File csvWriter = csvTester.CSVWriter(entry.getKey(),
	// readFieldNames);
	// fileList.add(csvWriter);
	// } catch (FileNotFoundException e) {
	// throw e;
	// }
	// }
	// getLogger().log(Level.INFO, "Adding files to zip- " + fileList);
	// String zipWriter = csvTester.zipWriter(fileList, jobID);
	//
	// return zipWriter;
	//
	// }

}
