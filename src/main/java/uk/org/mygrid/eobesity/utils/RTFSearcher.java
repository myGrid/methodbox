package uk.org.mygrid.eobesity.utils;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Map.Entry;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

import uk.org.mygrid.eobesity.csvserver.Messages;

public class RTFSearcher {

	private static final String DATA_FOLDER = Messages
			.getString("RTFSearcher.0"); //$NON-NLS-1$

	private Map<String, List<String>> variableInfo;

	private Map<String, List<String>> searchTerms;

	public RTFSearcher() {
		// setSearchTerms(new HashMap<String, List<String>>());
		//
		// List<String> ageList = new ArrayList<String>();
		// ageList.add("age");
		// ageList.add("birth");
		// ageList.add("date");
		// ageList.add("year");
		// ageList.add("month");
		// ageList.add("survey");
		// getSearchTerms().put("Age", ageList);
		//
		// List<String> sexList = new ArrayList<String>();
		// sexList.add("sex");
		// sexList.add("gender");
		// getSearchTerms().put("Sex", sexList);
		//
		// List<String> heightList = new ArrayList<String>();
		// heightList.add("height");
		// getSearchTerms().put("Height", heightList);
		//
		// List<String> weightList = new ArrayList<String>();
		// weightList.add("weight");
		// getSearchTerms().put("Weight", weightList);
		//
		// List<String> bmiList = new ArrayList<String>();
		// bmiList.add("bmi");
		// getSearchTerms().put("BMI", bmiList);
		//
		// List<String> ethnicityList = new ArrayList<String>();
		// ethnicityList.add("ethnic");
		// getSearchTerms().put("Ethnicity", ethnicityList);
		//
		// List<String> physicalActivityList = new ArrayList<String>();
		// physicalActivityList.add("workout");
		// physicalActivityList.add("weight train");
		// physicalActivityList.add("actbmin");
		// getSearchTerms().put("Physical_Activity", physicalActivityList);
		//
		// List<String> geographicalList = new ArrayList<String>();
		// geographicalList.add("area");
		// geographicalList.add("authority");
		// geographicalList.add("output");
		// geographicalList.add("geo");
		// geographicalList.add("rha");
		// geographicalList.add("post");
		// geographicalList.add("district");
		// geographicalList.add("strategic");
		// geographicalList.add("sha");
		// geographicalList.add("soa");
		// geographicalList.add("super");
		// getSearchTerms().put("Geographical", geographicalList);
		//
		// List<String> personIDList = new ArrayList<String>();
		// personIDList.add("person");
		// personIDList.add("identification");
		// personIDList.add("number");
		// personIDList.add("no");
		// getSearchTerms().put("Person_ID", personIDList);

	}

	/**
	 * DOESN"T REALLY WORK, the RTFEditorKit is a bit flaky
	 * 
	 * @param is
	 * @return
	 */
	// public Document getDocument(InputStream is) {
	// RTFEditorKit rtfEditorKit = new RTFEditorKit();
	//
	// Document document = rtfEditorKit.createDefaultDocument();
	//
	// // Read the document and flush the writer.
	// try {
	// rtfEditorKit.read(is, document, 0);
	// is.close();
	// } catch (IOException e) {
	// // TODO Auto-generated catch block
	// e.printStackTrace();
	// } catch (BadLocationException e) {
	// // TODO Auto-generated catch block
	// e.printStackTrace();
	// }
	// return document;
	//
	// }
	/**
	 * Search the variable description document for the appropriate year for the
	 * field supplied
	 * 
	 * @param field
	 * @param year
	 * @throws Exception
	 */
	public Element searchDocument(String field, String year,
			org.w3c.dom.Document document, List<String> terms) throws Exception {
		// TODO maybe cache the searches based on the field and the terms ie. if
		// they are the same then we can just return some old results
		// load and parse the variable description doc

		// keep a record of what term maps to what variable matches
		// Map<String, List<String>> termToNodeList = new HashMap<String,
		// List<String>>();
		FileInputStream fstream = null;
		try {
			fstream = new FileInputStream(DATA_FOLDER + year
					+ File.separator + "HSE" + year + "Description.txt"); //$NON-NLS-1$ //$NON-NLS-2$
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
		documentParser(fstream);

		// search the doc for all the terms
		List<String> matchingTerms = new ArrayList<String>();
		// List<String> list = getSearchTerms().get(field);

		Element parentElement = document.createElement("content"); //$NON-NLS-1$
		Element databaseElement = document.createElement("data"); //$NON-NLS-1$
		parentElement.appendChild(databaseElement);

		Set<Entry<String, List<String>>> entrySet = variableInfo.entrySet();
		for (String term : terms) {
			// List<String> termList = new ArrayList<String>();
			// termToNodeList.put(term, termList);
			for (Entry<String, List<String>> entry : entrySet) {
				String key = entry.getKey();
				if (key.equalsIgnoreCase(term)) {
					matchingTerms.add(entry.getKey());
					break;
				}
				List<String> value = entry.getValue();
				// String substring = term.substring(0, 1);
				// String upperCase = substring.toUpperCase();
				// String substring2 = term.substring(1, term.length());
				for (String val : value) {
					// String upperCaseWord = upperCase + substring2;
					//					
					// String regex = "\b[" + substring + upperCase + "]"
					// + substring2 + "\b";
					try {
						String[] split = val.split(" "); //$NON-NLS-1$
						for (String splitLine : split) {
							if (splitLine.equalsIgnoreCase(term)) {
								// some of the description for the variable has
								// matched so we can break out
								// termList.add(entry.getKey());
								matchingTerms.add(entry.getKey());
								break;
							}
						}

					} catch (Exception e) {
						System.out.println(e);
					}

				}
			}

		}
		if (matchingTerms.size() > 100) {
			throw new Exception(
					"Too many matching fields, narrow the search and try again"); //$NON-NLS-1$
		}
		// turn matching terms into XML and send back across
		// String xmlDoc = "<matching>\n";
		for (String term : matchingTerms) {
			Element rowElement = document.createElement("user"); //$NON-NLS-1$
			databaseElement.appendChild(rowElement);
			Element nameElement = document.createElement("field"); //$NON-NLS-1$
			rowElement.appendChild(nameElement);
			nameElement.appendChild(document.createTextNode(term));
			// xmlDoc = xmlDoc + "<variable>\n" + "<name>" + term + "</name>\n";
			List<String> list2 = variableInfo.get(term);
			Element labelElement = document.createElement("label"); //$NON-NLS-1$
			rowElement.appendChild(labelElement);
			labelElement.appendChild(document.createTextNode(variableInfo.get(
					term).get(0)));
			String infoString = ""; //$NON-NLS-1$
			for (int i = 1; i < list2.size() - 1; i++) {
				if (list2.get(i).length() == 0) {
					continue;
				}
				infoString = infoString + list2.get(i).trim() + "\n"; //$NON-NLS-1$
				// xmlDoc = xmlDoc + "<description>" + list2.get(i) +
				// "</description>\n";
			}
			Element infoElement = document.createElement("info"); //$NON-NLS-1$
			rowElement.appendChild(infoElement);
			infoElement.appendChild(document.createTextNode(infoString));
			// xmlDoc = xmlDoc + "</variable>\n";
		}
		// add some elements which let the user know how many hits each term has
		// generated
		// Element matchesElement = document.createElement("matches");
		// int totalHits = 0;
		// document.appendChild(matchesElement);
		// for (Entry<String, List<String>> entry:termToNodeList.entrySet()) {
		// String key = entry.getKey();
		// int size = entry.getValue().size();
		// Element matchElement = document.createElement("match");
		// matchElement.setAttribute("name", key);
		// matchElement.setAttribute("size", Integer.toString(size));
		// matchesElement.appendChild(matchElement);
		// totalHits = totalHits + size;
		// }
		// Element totalHitsElement = document.createElement("totalHits");
		// totalHitsElement.appendChild(document.createTextNode(Integer.toString(totalHits)));
		// matchesElement.appendChild(totalHitsElement);
		// xmlDoc = xmlDoc + "</matching>\n";

		return parentElement;
	}

	/**
	 * Parses a description text file in the 'nominal' HSE format (ie. complete
	 * guess since there is no schema) and populates a description of each field
	 * name. Completes a Map of field name to a List of the descriptions.
	 * Includes the variable label
	 * 
	 * @param is
	 */
	public void documentParser(InputStream is) {

		setVariableInfo(new HashMap<String, List<String>>());

		BufferedReader reader = new BufferedReader(new InputStreamReader(is));

		boolean next = false;
		String line = ""; //$NON-NLS-1$
		try {
			String variableName = null;
			String variableLabel = null;
			while ((line = reader.readLine()) != null) {
				String trim = line.trim();
				if (trim.startsWith("Pos")) { //$NON-NLS-1$

					next = true;
					// we have the first line of the variable descriptor

					String[] split = line.split("="); //$NON-NLS-1$

					// find the variable label
					int lastIndexOf = line.lastIndexOf("Variable label"); //$NON-NLS-1$

					if (lastIndexOf != -1) {
						// Variable label exists
						String substring2 = line.substring(lastIndexOf);
						// ie \ = \ blah blah blah

						if (substring2 != null) {
							String[] split2 = substring2.split("="); //$NON-NLS-1$
							// should be variable label with trailing and
							// leading spaces removed
							variableLabel = split2[1].trim();
						} else {
							variableLabel = "No label"; //$NON-NLS-1$
						}

					} else {
						variableLabel = "No label"; //$NON-NLS-1$
					}

					// find the variable name

					int indexOf = line.indexOf("Variable"); //$NON-NLS-1$
					String substring = line.substring(indexOf);
					// should be Variable = blah Variable label = blah
					String[] split2 = substring.split("="); //$NON-NLS-1$
					// should have Variable, blah Variable label, blah
					int indexOf2 = split2[1].indexOf("Variable"); //$NON-NLS-1$
					if (indexOf2 != -1) {
						String substring2 = split2[1]
								.substring(0, indexOf2 - 1);
						// only blah
						variableName = substring2.trim();
						List<String> info = new ArrayList<String>();
						info.add(variableLabel);
						getVariableInfo().put(variableName, info);

					} else {
						// there is no variable label so look for 'This
						// variable...'
						int indexOf3 = split2[1].indexOf("This"); //$NON-NLS-1$
						String substring2 = split2[1]
								.substring(0, indexOf3 - 1);
						variableName = substring2.trim();

						List<String> info = new ArrayList<String>();
						info.add(variableLabel);
						getVariableInfo().put(variableName, info);
					}

				} else {
					if (next) {
						getVariableInfo().get(variableName).add(line);
					}
				}
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		try {
			is.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

	/**
	 * Turn the description file into an XML version for easier parsing/reading
	 * 
	 * @param year
	 */
	public void writeXML(String year) {

		FileInputStream fstream = null;
		try {
			fstream = new FileInputStream(DATA_FOLDER + year
					+ File.separator + "HSE" + year + "Description.txt"); //$NON-NLS-1$ //$NON-NLS-2$
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
		documentParser(fstream);

		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		Document newDocument = null;
		try {
			newDocument = factory.newDocumentBuilder().newDocument();
		} catch (ParserConfigurationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		Element parentElement = newDocument.createElement("metadata"); //$NON-NLS-1$
		parentElement.setAttribute("year", year); //$NON-NLS-1$
		newDocument.appendChild(parentElement);
		try {
			for (Entry<String, List<String>> variable : variableInfo.entrySet()) {
				String key = variable.getKey();
				Element variableElement = newDocument.createElement("variable"); //$NON-NLS-1$
				Element nameElement = newDocument.createElement("name"); //$NON-NLS-1$
				variableElement.appendChild(nameElement);
				nameElement.appendChild(newDocument.createTextNode(key));
				parentElement.appendChild(variableElement);
				List<String> value = variable.getValue();
				// index 0 is the description
				String description = value.get(0);
				Element descriptionElement = newDocument
						.createElement("description"); //$NON-NLS-1$
				descriptionElement.appendChild(newDocument
						.createTextNode(description));
				variableElement.appendChild(descriptionElement);
				Element informationElement = newDocument
						.createElement("information"); //$NON-NLS-1$
				variableElement.appendChild(informationElement);
				boolean SPSS = false;
				for (int x = 1; x < value.size(); x++) {
					String trim = value.get(x).trim();
					String[] split = trim.split("="); //$NON-NLS-1$
					// if we can split then we have Value = X Label = Y so get
					// these
					// bits
					if (split.length > 0 && split.length == 3) {
						String trim2 = split[1].trim();
						int indexOf = trim2.indexOf("Label"); //$NON-NLS-1$
						// value
						String substring = trim2.substring(0, indexOf);
						// label
						String trim3 = split[2].trim();
						Element infoElement = newDocument.createElement("info"); //$NON-NLS-1$
						Element valueElement = newDocument
								.createElement("Value"); //$NON-NLS-1$
						infoElement.appendChild(valueElement);
						valueElement.appendChild(newDocument
								.createTextNode(substring));
						// variableElement.appendChild(valueElement);

						Element labelElement = newDocument
								.createElement("Label"); //$NON-NLS-1$
						infoElement.appendChild(labelElement);
						labelElement.appendChild(newDocument
								.createTextNode(trim3));
						informationElement.appendChild(infoElement);
						SPSS = false;

					} else if (split[0].trim().contains("SPSS") && !SPSS) { //$NON-NLS-1$
						SPSS = true;
						// we have SPSS blah blah blah so get the next line
					} else if (SPSS) {
						if (split.length == 2) {
							String trim2 = split[1].trim();
							Element missingValuesElement = newDocument
									.createElement("MissingValues"); //$NON-NLS-1$
							missingValuesElement.appendChild(newDocument
									.createTextNode(trim2));
							variableElement.appendChild(missingValuesElement);
							SPSS = false;
						}
					}

				}

			}
		} catch (Exception e) {
			System.out.println(e);
		}
		File file = null;
		FileOutputStream stream = null;
		try {
			file = new File(DATA_FOLDER + year + File.separator + "descxml.xml"); //$NON-NLS-1$ //$NON-NLS-2$
			stream = new FileOutputStream(file);
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		TransformerFactory tFactory = TransformerFactory.newInstance();
		Transformer transformer;
		try {
			transformer = tFactory.newTransformer();
			DOMSource source = new DOMSource(newDocument);
			StreamResult result = new StreamResult(file);

			transformer.transform(source, result);
		} catch (TransformerConfigurationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (TransformerException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

	/**
	 * Load the correct metadata doc for the year and using XPATH query get the
	 * Variable elements that match the names
	 * 
	 * @param document
	 * @param varNames
	 * @param year
	 */
	public void readVariables(Document document, List<String> varNames,
			String year) {
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		factory.setNamespaceAware(true);
		// Now use the factory to create a DOM parser (a.k.a. a DocumentBuilder)
		DocumentBuilder parser = null;
		try {
			parser = factory.newDocumentBuilder();
		} catch (ParserConfigurationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		InputStream stream = null;
		File file;
		try {
			// FIXME turn these into resources or properties - not hard coded!!
			file = new File(DATA_FOLDER + year + File.separator //$NON-NLS-1$
					+ year + "descxml.xml"); //$NON-NLS-1$
			stream = new FileInputStream(file);
		} catch (FileNotFoundException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}

		// Parse the file and build a Document tree to represent its content
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
		Element element = document.createElement("Variables"); //$NON-NLS-1$
		document.appendChild(element);

		for (String name : varNames) {
			String query = "//variable[name=\"" + name + "\"]"; //$NON-NLS-1$ //$NON-NLS-2$
			XPathExpression expr = null;
			try {
				expr = xpath.compile(query);
			} catch (XPathExpressionException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			Node result = null;
			try {
				result = (Node) expr.evaluate(xmlDoc, XPathConstants.NODE);
				Node importNode = document.importNode(result, true);
				element.appendChild(importNode);
				// element.appendChild(result);
				// document.appendChild(result);

			} catch (XPathExpressionException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		// Transformer transformer = null;
		// try {
		// transformer = TransformerFactory.newInstance().newTransformer();
		// } catch (TransformerConfigurationException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// } catch (TransformerFactoryConfigurationError e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
		// // transformer.setOutputProperty(OutputKeys.INDENT, "yes");
		//
		// // initialize StreamResult with File object to save to file
		// StreamResult streamResult = new StreamResult(new StringWriter());
		// DOMSource source = new DOMSource(result);
		// try {
		// transformer.transform(source, streamResult);
		// } catch (TransformerException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
		//
		// String xmlString = streamResult.getWriter().toString();
		// System.out.println(xmlString);
		// }
		// Transformer transformer = null;
		// try {
		// transformer = TransformerFactory.newInstance().newTransformer();
		// } catch (TransformerConfigurationException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// } catch (TransformerFactoryConfigurationError e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
		// // transformer.setOutputProperty(OutputKeys.INDENT, "yes");
		//
		// // initialize StreamResult with File object to save to file
		// StreamResult streamResult = new StreamResult(new StringWriter());
		// DOMSource source = new DOMSource(document);
		// try {
		// transformer.transform(source, streamResult);
		// } catch (TransformerException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
		//
		// String xmlString = streamResult.getWriter().toString();
		// System.out.println(xmlString);

	}

	/**
	 * Get the label/description for a particular variable in a year. Add it to
	 * the source document via the Element which will desribe that variable
	 * 
	 * @param document
	 * @param element
	 * @param variable
	 * @param year
	 */
	public void getLabelForVariable(Document document, Element element,
			String variable, String year) {
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		factory.setNamespaceAware(true);
		// Now use the factory to create a DOM parser (a.k.a. a DocumentBuilder)
		DocumentBuilder parser = null;
		try {
			parser = factory.newDocumentBuilder();
		} catch (ParserConfigurationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		InputStream stream = null;
		File file;
		try {
			// FIXME turn these into resources or properties - not hard coded!!
			String str = DATA_FOLDER + year + File.separator + year //$NON-NLS-1$ //$NON-NLS-2$
					+ "descxml.xml"; //$NON-NLS-1$
//			String encode = URLEncoder.encode(str, "UTF-8");
			file = new File(str);
			stream = new FileInputStream(file);
		} catch (FileNotFoundException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}

		// Parse the file and build a Document tree to represent its content
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

		String query = "//variable[name=\"" + variable + "\"]/description"; //$NON-NLS-1$ //$NON-NLS-2$
		XPathExpression expr = null;
		Node descriptionNode;
		String description = null;
		try {
			expr = xpath.compile(query);
			descriptionNode = (Node) expr.evaluate(xmlDoc, XPathConstants.NODE);
			description = descriptionNode.getFirstChild().getNodeValue();

		} catch (XPathExpressionException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		Element labelElement = document.createElement("Label"); //$NON-NLS-1$
		labelElement.appendChild(document.createTextNode(description));
		element.appendChild(labelElement);
	}

	public void searchXMLForTerms(Document document, List<String> terms,
			String year) {
		Map<String, List<Node>> termToNodeList = new HashMap<String, List<Node>>();
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		factory.setNamespaceAware(true);
		// Now use the factory to create a DOM parser (a.k.a. a DocumentBuilder)
		DocumentBuilder parser = null;
		try {
			parser = factory.newDocumentBuilder();
		} catch (ParserConfigurationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		InputStream stream = null;
		File file;
		try {
			// FIXME turn these into resources or properties - not hard coded!!
			String str = DATA_FOLDER + year + File.separator + year //$NON-NLS-1$ //$NON-NLS-2$
					+ "descxml.xml"; //$NON-NLS-1$
			file = new File(str);
			stream = new FileInputStream(file);
		} catch (FileNotFoundException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}

		// Parse the file and build a Document tree to represent its content
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
		// Element element = document.createElement("Variables");
		// document.appendChild(element);

		String query = "//metadata"; //$NON-NLS-1$
		XPathExpression expr = null;

		NodeList nodes = xmlDoc.getElementsByTagName("variable"); //$NON-NLS-1$
		// loop over all the variable XML fragments
		// variable - name - missing values - info
		for (String term : terms) {
			List<Node> nodeListForTerm = new ArrayList<Node>();
			termToNodeList.put(term, nodeListForTerm);
			// search the label and each bit of 'info' in the XML for the term
			for (int i = 0; i < nodes.getLength(); i++) {
				// get the first variable
				Node item = nodes.item(i);

				// XPATH to get the name etc.
				Node nameNode;
				Node descriptionNode;
				Node missingValuesNode;
				NodeList infoNodes;
				boolean searchTextFragment1 = false;
				boolean searchTextFragment2 = false;
				boolean searchTextFragment3 = false;
				try {
					query = "//name"; //$NON-NLS-1$
					expr = xpath.compile(query);
					nameNode = (Node) expr.evaluate(item, XPathConstants.NODE);
					String name = nameNode.getFirstChild().getNodeValue();
					searchTextFragment1 = searchTextFragment(name, term);

					query = "//description"; //$NON-NLS-1$
					expr = xpath.compile(query);
					descriptionNode = (Node) expr.evaluate(item,
							XPathConstants.NODE);
					String description = descriptionNode.getFirstChild()
							.getNodeValue();
					searchTextFragment2 = searchTextFragment(description, term);

					// query = "//MissingValues";
					// expr = xpath.compile(query);
					// missingValuesNode = (Node) expr.evaluate(item,
					// XPathConstants.NODE);
					// String missingValues = missingValuesNode.getFirstChild()
					// .getNodeValue();

					// get the info nodes
					query = "//variable[name=\"" + name //$NON-NLS-1$
							+ "\"]/information/info"; //$NON-NLS-1$
					expr = xpath.compile(query);
					infoNodes = (NodeList) expr.evaluate(xmlDoc,
							XPathConstants.NODESET);

					// loop over info nodes to get Value & Label

					for (int j = 0; j < infoNodes.getLength(); j++) {
						Node iNode = infoNodes.item(j);
						// query = "//Value";
						// expr = xpath.compile(query);
						// Node valueNode = (Node) expr.evaluate(iNode,
						// XPathConstants.NODE);
						// String val =
						// valueNode.getFirstChild().getNodeValue();
						query = "//Label"; //$NON-NLS-1$
						expr = xpath.compile(query);
						Node labelNode = (Node) expr.evaluate(iNode,
								XPathConstants.NODE);
						String lab = labelNode.getFirstChild().getNodeValue();
						searchTextFragment3 = searchTextFragment(lab, term);
					}
					if (searchTextFragment1 || searchTextFragment2
							|| searchTextFragment3) {
						termToNodeList.get(term).add(item);
					}
				} catch (XPathExpressionException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}

			}
		}
		// we now have a map of all the terms and all the XML which matched the
		// regex and can add this to the document

	}

	/**
	 * Use Regular Expression to find a match for a word in String. Use word
	 * boundaries so that matches inside a string are excluded
	 * 
	 * @param text
	 * @param match
	 * @return
	 */
	private boolean searchTextFragment(String text, String match) {
		String regex;
		if (match.length() > 1) {
			String trim = match.trim();
			// the first character in lower case
			String substring = trim.substring(0, 1).toLowerCase();
			// the rest of the string
			String substring2 = trim.substring(1, trim.length());
			regex = "\\b[" + substring.toUpperCase() + substring.toLowerCase() //$NON-NLS-1$
					+ "]" + substring2 + "\\b"; //$NON-NLS-1$ //$NON-NLS-2$
		} else {
			String substring = match.toLowerCase();
			regex = "\\b[" + substring.toUpperCase() + substring.toLowerCase() //$NON-NLS-1$
					+ "]\\b"; //$NON-NLS-1$
		}
		Pattern pattern = Pattern.compile(regex);
		// Get a matcher object - we cover this next.
		Matcher matcher = pattern.matcher(text);
		return matcher.find();
	}

	/**
	 * Get the original 'value map' for a particular variable and year from the
	 * source documents/xml file
	 * 
	 * @param document
	 * @param element
	 * @param variable
	 * @param year
	 */
	public void getValueMapForVariable(Document document, Element element,
			String variable, String year) {
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		factory.setNamespaceAware(true);
		// Now use the factory to create a DOM parser (a.k.a. a DocumentBuilder)
		DocumentBuilder parser = null;
		try {
			parser = factory.newDocumentBuilder();
		} catch (ParserConfigurationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		InputStream stream = null;
		File file;
		try {
			// FIXME turn these into resources or properties - not hard coded!!
			String str = DATA_FOLDER + year + File.separator + year //$NON-NLS-1$ //$NON-NLS-2$
					+ "descxml.xml"; //$NON-NLS-1$
			file = new File(str);
			stream = new FileInputStream(file);
		} catch (FileNotFoundException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}

		// Parse the file and build a Document tree to represent its content
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
		// Element element = document.createElement("Variables");
		// document.appendChild(element);

		String query = "//variable[name=\"" + variable + "\"]/information"; //$NON-NLS-1$ //$NON-NLS-2$
		XPathExpression expr = null;
		try {
			expr = xpath.compile(query);
		} catch (XPathExpressionException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		Node infoNode = null;
		try {
			infoNode = (Node) expr.evaluate(xmlDoc, XPathConstants.NODE);

		} catch (XPathExpressionException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		// Element createElement = document.createElement("original");
		Node importNode = document.importNode(infoNode, true);
		// createElement.appendChild(importNode);
		element.appendChild(importNode);
	}

	public static void main(String[] args) {

		RTFSearcher searcher = new RTFSearcher();
		// DocumentBuilder builder = null;
		// try {
		// builder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
		// } catch (ParserConfigurationException e1) {
		// // TODO Auto-generated catch block
		// e1.printStackTrace();
		// }
		// Document doc = builder.newDocument();

		// File file;
		// try {
		// file = new File(new URI("file:///Users/Ian/1993descxml.xml"));
		// } catch (URISyntaxException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
		// List<String> varList = new ArrayList<String>();
		// varList.add("age");
		// varList.add("height");
		// varList.add("weight");

		// searcher.readVariables(doc, varList, "1993");
		// searcher.searchXMLForTerms(doc, varList, "1993");

		searcher.writeXML("2005"); //$NON-NLS-1$
		// String searchDocument = searcher.searchDocument("Age", "2006");
		// System.out.println(searchDocument);

		// String statement =
		// "act14=[(D) Other sports intensity, This variable is  numeric, the SPSS measurement level is scale., SPSS user missing values = -99  thru -1, 	Value label information for act14, 	Value = -9	Label = No answer/refused, 	Value = -8	Label = Don't know, 	Value = -7	Label = Refused/not obtained, 	Value = -6	Label = Schedule not obtained, 	Value = -2	Label = Schedule not applicable, 	Value = -1	Label = Item not applicable, 	Value = 1	Label = Light type, 	Value = 2	Label = Moderate type, 	Value = 3	Label = Vigorous type, 	Value = 4	Label = Vigorous type ( swim ,cycle,weights,aerobic,football,tennis), 	Value = 5	Label = Very vigorous type (running, squash), ]";
		// String regex = "\\b[sS]wim\\b";
		// boolean matches = statement.matches(regex);
		// System.out.println(matches);
		// Document RTFDoc = new Document();
		// RTFDoc.open();

		// FileInputStream fstream = null;
		// try {
		// fstream = new FileInputStream(
		// "/Users/Ian/obesity_data/2006/HSE2006Description.txt");
		// } catch (FileNotFoundException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
		//
		// RTFSearcher searcher = new RTFSearcher();
		// searcher.documentParser(fstream);
		//
		// System.out.println("FINISHED PARSING");
		//
		// Set<Entry<String, List<String>>> entrySet =
		// searcher.getVariableInfo()
		// .entrySet();
		//
		// for (Entry entry : entrySet) {
		// List<String> value = (List<String>) entry.getValue();
		// System.out.println(entry.getKey());
		// for (String val : value) {
		// System.out.println(val);
		// }
		//
		// }

		// Document document = searcher.getDocument(fstream);
		// String plainText = null;
		// try {
		// plainText = document.getText(0, document.getLength());
		// } catch (BadLocationException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
		//
		// try {
		// BufferedWriter out = new BufferedWriter(new FileWriter(
		// "/Users/Ian/scratch/test.txt"));
		// out.write(plainText);
		// out.close();
		// } catch (IOException e) {

		// RtfParser parserRTF = new RtfParser(RtfDoc);
		// try {
		// parserRTF.convertRtfDocument(fstream, RTFDoc);
		// } catch (IOException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }

	}

	public void setVariableInfo(Map<String, List<String>> variableInfo) {
		this.variableInfo = variableInfo;
	}

	public Map<String, List<String>> getVariableInfo() {
		return variableInfo;
	}

	public void setSearchTerms(Map<String, List<String>> searchTerms) {
		this.searchTerms = searchTerms;
	}

	public Map<String, List<String>> getSearchTerms() {
		return searchTerms;
	}
}
