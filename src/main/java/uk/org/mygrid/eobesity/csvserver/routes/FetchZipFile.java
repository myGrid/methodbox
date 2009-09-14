package uk.org.mygrid.eobesity.csvserver.routes;

import java.io.File;
import java.io.IOException;
import java.util.logging.Level;

import org.restlet.Context;
import org.restlet.data.MediaType;
import org.restlet.data.Request;
import org.restlet.data.Response;
import org.restlet.data.Status;
import org.restlet.resource.DomRepresentation;
import org.restlet.resource.FileRepresentation;
import org.restlet.resource.Representation;
import org.restlet.resource.Resource;
import org.restlet.resource.Variant;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import uk.org.mygrid.eobesity.csvserver.Messages;

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
public class FetchZipFile extends Resource {

	/** The UUID representing the job being run */
	private String jobID;

	public FetchZipFile(Context context, Request request, Response response) {
		super(context, request, response);
		this.jobID = (String) request.getAttributes().get("jobid");
		getVariants().add(new Variant(MediaType.TEXT_XML));
	}

	@Override
	public boolean allowGet() {
		return true;
	}

	@Override
	public Representation getRepresentation(Variant variant) {
		if (DownloadFile.getFailedJobs().contains(jobID)) {
			DomRepresentation representation;
			try {
				representation = new DomRepresentation(MediaType.TEXT_XML);
				Document d = representation.getDocument();
				Element jobIDElement = d.createElement("status");
				jobIDElement.appendChild(d.createTextNode("Failed"));
				d.appendChild(jobIDElement);
				d.normalizeDocument();
				getResponse().setEntity(d);
				getResponse().setStatus(Status.SERVER_ERROR_INTERNAL);
				return representation;
			} catch (IOException e) {
				getLogger().log(Level.WARNING,
						"Problem returning status for job " + jobID);
				getResponse().setStatus(Status.SERVER_ERROR_INTERNAL);
			}
		} else {
			Boolean completedJob = DownloadFile.getCompletedJobList()
					.get(jobID);
			if (completedJob == null) {
				getLogger().log(Level.INFO,
						"No such job " + jobID);
				getResponse().setStatus(Status.CLIENT_ERROR_BAD_REQUEST);
			}
			else if (completedJob) {
				getLogger().log(Level.INFO,
						"Job " + jobID + " complete, returning zip file");
				// return the completed file
				String fileDirectory = Messages.getString("DownloadFile.31");
				File file = new File(fileDirectory + jobID + ".zip");
				FileRepresentation representation = new FileRepresentation(
						file, MediaType.APPLICATION_ZIP, 12345);
				getResponse().setEntity(representation);
				getResponse().setStatus(Status.SUCCESS_OK);
				return representation;
			} else {
				// return an xml doc with '<status>false</status>'
				DomRepresentation representation;
				try {
					representation = new DomRepresentation(MediaType.TEXT_XML);
					Document d = representation.getDocument();
					Element jobIDElement = d.createElement("status");
					// String progress =
					// DownloadFile.getNumberProcessed().get(jobID);
					jobIDElement.appendChild(d
							.createTextNode("Still processing"));
					d.appendChild(jobIDElement);
					d.normalizeDocument();
					getResponse().setEntity(d);
					getResponse().setStatus(Status.SUCCESS_OK);
					return representation;
				} catch (IOException e) {
					getLogger().log(Level.WARNING,
							"Problem returning status for job " + jobID);
					getResponse().setStatus(Status.SERVER_ERROR_INTERNAL);
				}

			}
		}

		return null;

	}
}
