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
		for(x in termsHash[term]) {
			Element.show($(termsHash[term][x])); //something
		}
	} else {
		//hide the variables
		for(x in termsHash[term]) { //x is the variable from the term that has been unchecked
			for(var key in termsHash) {
				if (key != term && termsOn[key]) {//if the checkbox for another term has been clicked previously
					for (currvar in termsHash[key]) {//the variables in a term that has already been checked
						//see if the variable is in the variable array for the checked term
						// (are you following this - it seems a bit too complex!)
						if (termsHash[key].indexOf(termsHash[term][x]) != -1) {//if the variable is visible but could be hidden due to the term that was clicked
							Element.show($(termsHash[term][x]));//show the variable
						} else {
							Element.hide($(termsHash[term][x]));//hide the variable
							Element.hide($(termsHash[term][x] + '_expanded'));
						}
					}
				}
		}
	}
}
}