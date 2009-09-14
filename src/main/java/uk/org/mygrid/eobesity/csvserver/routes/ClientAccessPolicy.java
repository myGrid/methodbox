package uk.org.mygrid.eobesity.csvserver.routes;

import java.io.IOException;
import java.util.logging.Level;

import org.restlet.Context;

import org.restlet.data.MediaType;

import org.restlet.data.Request;

import org.restlet.data.Response;

import org.restlet.resource.DomRepresentation;

import org.restlet.resource.Representation;

import org.restlet.resource.Resource;

import org.restlet.resource.Variant;

import org.w3c.dom.Document;

import org.w3c.dom.Element;

public class ClientAccessPolicy extends Resource {
	
	private static final String LOGGER_NAME = "org.mortbay.log";

	public ClientAccessPolicy(Context context, Request request,

	Response response) {

		super(context, request, response);

		getVariants().add(new Variant(MediaType.TEXT_XML));

	}

	@Override
	public Representation getRepresentation(Variant variant) {
		
		java.util.logging.Logger.getLogger(LOGGER_NAME).log(Level.INFO,
		"client access");

		if (MediaType.TEXT_XML.equals(variant.getMediaType())) {

			try {

				DomRepresentation representation = new DomRepresentation(

				MediaType.TEXT_XML);

				// Generate a DOM document representing the list of

				// items.

				Document d = representation.getDocument();

				Element accesspolicy = d.createElement("cross-domain-policy");

				d.appendChild(accesspolicy);

				Element crossdomainaccess = d
						.createElement("allow-access-from");
				crossdomainaccess.setAttribute("domain", "127.0.0.1");
				crossdomainaccess.setAttribute("secure", "false");
		

				accesspolicy.appendChild(crossdomainaccess);

				d.normalizeDocument();

				// Returns the XML representation of this document.

				return representation;

			} catch (IOException e) {

				e.printStackTrace();

			}

		}

		return null;

	}

}