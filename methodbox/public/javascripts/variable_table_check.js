//which term maps to what vars
var termsHash = {};

//keep track of what terms have been clicked
var termsOn = {};

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
							Element.hide($(x));//hide the variable
							Element.hide($(x + '_expanded'));
							//switch off the checkbox for that variable
							$(x +'_checkbox').checked = false;
						}	
				} else {
					Element.hide($(x));//hide the variable
					Element.hide($(x + '_expanded'));
					//switch off the checkbox for that variable
					$(x +'_checkbox').checked = false;
				}
		}
		});
	}
}