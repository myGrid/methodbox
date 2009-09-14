To generate WAR file use mvn package
Sample request & response files for REST operations are in request.xml/response.xml
When deploying to a servlet container the path is currently http://host:port/csv-server-0.0.1-SNAPSHOT/ (although you can change the war file name!)
A standalone Jetty server can also be used  - run CSVServer.  It uses port 25000 and the path is http://host:25000/

