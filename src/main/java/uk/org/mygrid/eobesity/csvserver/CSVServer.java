package uk.org.mygrid.eobesity.csvserver;

import org.restlet.Component;
import org.restlet.data.Protocol;

public class CSVServer {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		Component component = new Component();
        // Add a new HTTP server listening on port 25000.
//        component.getServers().add(Protocol.HTTPS, 25000);
        component.getServers().add(Protocol.HTTP, 25000);
        
//        Series<Parameter> parameters = component.getServers().getContext().getParameters();
//        parameters.add("sslContextFactory", "com.noelios.restlet.ext.ssl.PkixSslContextFactory");
//        parameters.add("keystorePath", "/Users/Ian/keystore");
//        parameters.add("keystorePassword", "obesity");
//        parameters.add("keyPassword", "obesity");
//        parameters.add("keystoreType", "JKS");

        // Attach the sample application.
        component.getDefaultHost().attach(
                new CSVRESTService(component.getContext()));
        

        // Start the component.
        try {
			component.start();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

}
