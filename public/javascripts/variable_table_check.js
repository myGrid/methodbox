//which term maps to what vars
var termsHash = {};

//keep track of what terms have been clicked
var termsOn = {};

//what terms are currently highlighted
var termsHighlight = {};

//variable to its striping odd/even colour
var stripesHash = {};

//keep track of which variables have been selected
var variables_checked = [];

//add all the variables to the hash of search terms
function addVariable(term, variable) {
	if (termsHash[term] == null) {
		termsHash[term] = [];
		termsOn[term] = true;
	}
	termsHash[term].push(variable);
	
}

//hide/show variables for a specific term
function clickTerm(term) {
	termsOn[term] = !termsOn[term];
	
	if (termsOn[term]) {
		//show the variables
			termsHash[term].each(function(x) {
				Element.show($(x));
			});
	} else {
		//hide the variables
		termsHash[term].each(function(x) {
			for(var key in termsHash) {
				if (key != term && termsOn[key]) {//if the checkbox for another term has been clicked previously					
						if (termsHash[key].indexOf(x) != -1) {//if the variable is visible due to another term but could be hidden due to the term that was clicked
							Element.show($(x));//make sure the variable shows
						} else {
							//might be an expanded row. might not try-catch just in case the element does not exist
							try {
								Element.hide($(x));//hide the variable
							} catch (err) {
							}
							try {
								Element.hide($(x + '_expanded'));
								//switch off the checkbox for that variable
								$(x +'_checkbox').checked = false;
							} catch (err) {
							}
						}	
				} else {
					try {
						Element.hide($(x));//hide the variable
					} catch (err) {
					}
					try {
						Element.hide($(x + '_expanded'));
						//switch off the checkbox for that variable
						$(x +'_checkbox').checked = false;
					} catch (err) {
					}
				}
		}
		});
	}
}

//when creating the table keep note of the striping so
//we can reset it properly after highlighting any variables for
//a particular term
function setVariableStripe(variable, stripe) {
	stripesHash[variable] = stripe;
	//odd #EEEEEE
	//even none
}

//highlight the rows for a particular term
//only one can be highlighted at a time
function highlightTerm(term) {
	if (term=='no_terms_to_highlight') {
		//user clicked on 'none'
		for (var key in termsHighlight) {
		if (termsHighlight[key] == true) {
			//switch off the current highlight
			termsHash[key].each(function(x) {
				if (stripesHash[x] == "_odd") {
					//might be an expanded row. might not try-catch just in case the element does not exist
					try {
						$(x).down('ul').setStyle({backgroundColor:"#EEEEEE"});
					} catch (err) {
					}
					try {
						$(x + '_expanded').down('ul').setStyle({backgroundColor:"#EEEEEE"});
						$(x + '_expanded').setStyle({backgroundColor:"#EEEEEE"});
					} catch (err) {
					}
				} else {
					try {
						$(x).down('ul').setStyle({backgroundColor:"#FFFFFF"});
					} catch (err) {
					}
					try {
						$(x + '_expanded').down('ul').setStyle({backgroundColor:"#FFFFFF"});
						$(x + '_expanded').setStyle({backgroundColor:"#FFFFFF"});
					} catch (err) {
					}
				}
			});
			termsHighlight[key] = false;
			//can only be one highlighted at a time
			break;
		}
	}
}	else {
		for (var key in termsHighlight) {
		if (termsHighlight[key] == true) {
			//switch off the current highlight
			termsHash[key].each(function(x) {
				if (stripesHash[x] == "_odd") {
					try {
						$(x).down('ul').setStyle({backgroundColor:"#EEEEEE"});
					} catch (err) {
					}
					try {
						$(x + '_expanded').down('ul').setStyle({backgroundColor:"#EEEEEE"});
						$(x + '_expanded').setStyle({backgroundColor:"#EEEEEE"});
					} catch (err) {
					}
				} else {
					try {
						$(x).down('ul').setStyle({backgroundColor:"#FFFFFF"});
					} catch (err) {
					}
					try {
						$(x + '_expanded').down('ul').setStyle({backgroundColor:"#FFFFFF"});
						$(x + '_expanded').setStyle({backgroundColor:"#FFFFFF"});
					} catch (err) {
					}
				}
			});
			termsHighlight[key] = false;
			//can only be one highlighted at a time
			break;
		}
	}
	//switch on highlighting for the newly selected term
	termsHash[term].each(function(x) {
		try {
			$(x).down('ul').setStyle({backgroundColor:"#E2DDB5"});
		} catch (err) {
		}
		try {
			$(x + '_expanded').down('ul').setStyle({backgroundColor:"#E2DDB5"});
			$(x + '_expanded').setStyle({backgroundColor:"#E2DDB5"});
		} catch (err) {
		}
	});
	termsHighlight[term] = true;
}
}
//track which vars are clicked in the table and insert a hidden field 
//so that when submitted to the controller it knows which terms correspond
//to which variables
function addOrRemoveHiddenFieldForVariable(variable) {
	if ($(variable + '_checkbox').checked == false) {
		for(var key in termsHash) {
			if (termsHash[key].include(variable)) {
				$(key + '_' + variable + '_hidden_tracker').remove();
				break;
			}
		}
	} else {
			for(var key in termsHash) {
				if (termsHash[key].include(variable)) {
					var hidden_input = new Element('input',{'id':key + '_' + variable + '_hidden' + '_tracker','name': 'search_term_tracker[' + key + '][]','type':'hidden'});
					hidden_input.value = variable;
					$('search_tracker_div').insert(hidden_input);
					break;
				}
			}
	}
}

//Add or remove a dataset from the list
//of selected ones
function selectVariable(variable_id) {
  pos = variables_checked.indexOf(variable_id);
  if (pos != -1) {
    variables_checked.splice(pos, 1);
    $('selected_variable' + '_' + variable_id).remove();
  } else {
    variables_checked.push(variable_id);
    var hidden_input = new Element('input',{'id': 'selected_variable' + '_' + variable_id,'name': 'variable_ids[]','type':'hidden'});
    hidden_input.value = variable_id;
    $('selected_variables').insert(hidden_input);
  }
}

function anyVariablesSelected() {
  if ($('selected_variables').descendants().size() > 0) {
    return true;
  } else {
    return false;
  }
}
