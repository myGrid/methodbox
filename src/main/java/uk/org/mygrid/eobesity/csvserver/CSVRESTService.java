package uk.org.mygrid.eobesity.csvserver;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Map.Entry;
import java.util.logging.Handler;
import java.util.logging.Level;

import org.restlet.Application;
import org.restlet.Context;
import org.restlet.Restlet;
import org.restlet.Router;

import uk.org.mygrid.eobesity.csvserver.routes.ClientAccessPolicy;
import uk.org.mygrid.eobesity.csvserver.routes.DownloadFile;
import uk.org.mygrid.eobesity.csvserver.routes.FetchZipFile;
import uk.org.mygrid.eobesity.csvserver.routes.ReallySimpleFormatter;
import uk.org.mygrid.eobesity.utils.CSVTester;

/**
 * Sets up the routes ie URLs to class association for the CSV Dataset server
 * 
 * @author Ian Dunlop
 * 
 */
public class CSVRESTService extends Application {

	private static final String LOGGER_NAME = "org.mortbay.log";

	private static final String DOWNLOAD_CSV_DATASETS = "/eos/download";

	private static final String FETCH_ZIP_FILE = "/eos/download/{jobid}";

	private static final String CLIENT_ACCESS_POLICY = "/crossdomain.xml";

	public CSVRESTService(Context parentContext) {
		super(parentContext);
		init();
	}

	/**
	 * Set up logging and reload the completed job map
	 */
	private void init() {
		initializeRestletLogging();
		String serializeDirectory = Messages.getString("SerializeMap.0");
		File file = new File(serializeDirectory + "jobMap");
		try {
			FileInputStream stream = new FileInputStream(file);
			ObjectInputStream objectStream = new ObjectInputStream(stream);
			Map<String, Boolean> completedJobList = (Map<String, Boolean>) objectStream
					.readObject();
			objectStream.close();
			checkJobs(completedJobList);
			DownloadFile.setCompletedJobList(completedJobList);
		} catch (FileNotFoundException e) {
			getLogger().log(Level.INFO, "Problem de-serializing job map, " + e);
		} catch (IOException e) {
			getLogger().log(Level.INFO, "Problem de-serializing job map, " +e );
		} catch (ClassNotFoundException e) {
			getLogger().log(Level.INFO, "Problem de-serializing job map, " + e);
		}
	}

	/**
	 * When loading the job map they should all be complete, ie, true. If not
	 * then we have to re-run any that failed to complete
	 */
	private void checkJobs(Map<String, Boolean> completedJobList) {
		Set<Entry<String, Boolean>> entrySet = completedJobList.entrySet();
		for (Entry<String, Boolean> entry : entrySet) {
			if (entry.getValue() == false) {
				try {
					Map<String, List<String>> loadDatasetMap = loadDatasetMap(entry
							.getKey());
					entry.getKey();
					createJobThread(entry.getKey(), loadDatasetMap).start();
				} catch (Exception e) {
					// job failed and can't load the variables map so have to
					// mark it as failed so that the user
					// can see next time the look at it
					DownloadFile.getFailedJobs().add(entry.getKey());
					getLogger()
							.log(
									Level.INFO,
									"Problem loading dataset for job "
											+ entry.getKey()
											+ ", cannot re-run csv for this file. User must re-create. "
											+ e);
				}
			}
		}
	}

	/**
	 * Reload a dataset map for a job which failed to run to completion
	 * 
	 * @param uuid
	 * @return
	 * @throws IOException
	 * @throws ClassNotFoundException
	 */
	private Map<String, List<String>> loadDatasetMap(String uuid)
			throws IOException, ClassNotFoundException {
		String serializeDirectory = Messages.getString("SerializeMap.0");
		File file = new File(serializeDirectory + uuid + ".variableMap");
		try {
			FileInputStream stream = new FileInputStream(file);
			ObjectInputStream objectStream = new ObjectInputStream(stream);
			Map<String, List<String>> datasetToVariableMap = (Map<String, List<String>>) objectStream
					.readObject();
			objectStream.close();
			return datasetToVariableMap;
		} catch (FileNotFoundException e) {
			getLogger().log(Level.INFO, "Problem de-serializing job map");
			throw new FileNotFoundException("Problem de-serializing job map");
		} catch (IOException e) {
			getLogger().log(Level.INFO, "Problem de-serializing job map");
			throw new IOException("Problem de-serializing job map");
		} catch (ClassNotFoundException e) {
			getLogger().log(Level.INFO, "Problem de-serializing job map");
			throw new ClassNotFoundException("Problem de-serializing job map");
		}
	}

	/**
	 * Start the restlet server logging
	 */
	private void initializeRestletLogging() {

		Handler[] handlers = java.util.logging.Logger.getLogger("") //$NON-NLS-1$
				.getHandlers();
		for (Handler handler : handlers) {
			handler.setFormatter(new ReallySimpleFormatter());
		}
		java.util.logging.Logger.getLogger(LOGGER_NAME).setLevel(Level.INFO);

	}

	/**
	 * Creates all the Routes for the Restlet server. Associates urls with the
	 * classes which handle them
	 */
	@Override
	public Restlet createRoot() {
		// java.util.logging.Logger.getLogger(LOGGER_NAME).log(Level.INFO,
		// "Creating csv server routes");
		Router router = new Router(getContext());

		router.attach(CLIENT_ACCESS_POLICY, ClientAccessPolicy.class);

		router.attach(FETCH_ZIP_FILE, FetchZipFile.class);

		router.attach(DOWNLOAD_CSV_DATASETS, DownloadFile.class);

		return router;
	}

	/**
	 * Create a new job thread for a job which previously failed to run to
	 * completion
	 * 
	 * @param jobID
	 * @param datasetToVariableMap
	 * @return
	 */
	private Thread createJobThread(final String jobID,
			final Map<String, List<String>> datasetToVariableMap) {
		getLogger().log(Level.INFO, "Re-running CSV data for " + jobID);
		Thread thread = new Thread(new Runnable() {

			public void run() {
				try {

					Set<Entry<String, List<String>>> entrySet = datasetToVariableMap
							.entrySet();
					List<File> fileList = new ArrayList<File>();
					CSVTester csvTester = new CSVTester();
					for (Entry<String, List<String>> entry : entrySet) {
						Map<String, List<String>> readFieldNames;
						try {
							String key = entry.getKey();
							List<String> value = entry.getValue();
							getLogger().log(Level.INFO,
									"Loading data- " + key + ": " + value);
							readFieldNames = csvTester.readFieldNames(key,
									value);

							getLogger().log(Level.INFO,
									"Creating file- " + key + ": " + value);
							File csvWriter = csvTester.CSVWriter(
									entry.getKey(), readFieldNames, jobID);
							fileList.add(csvWriter);
						} catch (FileNotFoundException e) {
							throw e;
						}
					}
					getLogger().log(Level.INFO,
							"Adding files to zip- " + fileList);
					csvTester.zipWriter(fileList, jobID);

					DownloadFile.getCompletedJobList().put(jobID, true);
					getLogger().log(Level.INFO,
							DownloadFile.getCompletedJobList().toString());
				} catch (FileNotFoundException e) {
					// TODO need to log this error somewhere, maybe write it
					// out to the
					// file that the user gets
				}
			}

		});
		return thread;
	}

}
