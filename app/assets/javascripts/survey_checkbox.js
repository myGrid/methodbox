//a list of the 'check all' datasets checkbox
//and whether it is true or false
var checkedSurveyMap = {};
var allSurveyToDatasetsMap = {};
//keep a list of all the datasets and whether an individual one
//has been selected
var allDatasetsMap ={};

//if a particular dataset checkbox is clicked and is set to
//false then unclick the 'select all' checkbox if it is true 
function checkSelectAllStatus(survey_id, dataset_id) {
//TODO click the select all box by 'magic' if all the datasets for a survey have been selected manually
	$$('input.survey_checkbox').each(function(checkbox) { { if (Element.identify(checkbox).startsWith(survey_id + "_survey_check") ) {checkbox.checked = false }} });
	if (checkedSurveyMap[survey_id] == null) {
		checkedSurveyMap[survey_id] = false;
	} else {
		checkedSurveyMap[survey_id] = false;
	}
	//keep track of whether a checkbox has been clicked or not
	if (allDatasetsMap[survey_id + '_' + dataset_id] == false) {
		allDatasetsMap[survey_id + '_' + dataset_id] = true;
			allSurveyToDatasetsMap[survey_id].push(dataset_id);
	} else {
		allDatasetsMap[survey_id + '_' + dataset_id] = false;
		//remove the last value, doesn't matter what it is since we are only
		//using it as a count.  when the array length gets to 0 then there are 
		//no datasets selected for that survey
		allSurveyToDatasetsMap[survey_id].pop();
	}
	if (allSurveyToDatasetsMap[survey_id].length == 0) {
			//change colour to grey
			changeColour(survey_id, false);
	} else {
			//change colour to green
			changeColour(survey_id, true);
	}	
	showOrHideDatasetList();	
		
}
//when a new dataset checkbox is created then store it
//in a map of all the surveys to their datasets
function addDataset(survey_id, dataset_id) {
	var dataset_array = [];
	allDatasetsMap[survey_id + '_' + dataset_id] = false;
	if (allSurveyToDatasetsMap[survey_id] == null) {
		allSurveyToDatasetsMap[survey_id] = dataset_array;
	} 
	//each survey has 'x' datasets, add them to this map.  the actual value
	//of the dataset is not really important, we just want to know when this length 
	//reaches zero

}

//change the background colour for a survey box
//depending on its selection status
function changeColour(survey_id, selected) {
	if (selected) {
		$(survey_id + '_survey_box').setStyle({backgroundColor:"#E2DDB5"});
		$(survey_id + '_div').setStyle({backgroundColor:"#E2DDB5"});
	} else {
		$(survey_id + '_survey_box').setStyle({backgroundColor: "#CCC"});
		$(survey_id + '_div').setStyle({backgroundColor:"#CCC"});
	}
	
}

//used to show the dataset list under a
//particular survey
function hideOrShowThisDiv(id) {
	if ($(id+'_div').style.display == 'none') {
		$(id+'_div').show();	
	} else {
		$(id+'_div').hide();		
	}
}

function setDatasets(survey_id, checked) {
	var dataset_array = [];
	if (allSurveyToDatasetsMap[survey_id] == null) {
		allSurveyToDatasetsMap[survey_id] = dataset_array;
	}
	for (var dataset_id in allDatasetsMap) {
		if (dataset_id.startsWith(survey_id +"_")) {
			if (!allDatasetsMap[dataset_id] == checked) {
				allDatasetsMap[dataset_id] = checked;
				if (checked) {
					allSurveyToDatasetsMap[survey_id].push(1);
				} else {
					allSurveyToDatasetsMap[survey_id].pop();
				}
			}
		}
	}
}

//select all of the datasets for a particular
//survey when the select all checkbox is clicked
//change the colour of the datasets box if colour is true
function selectAllDatasetsForYear(id, colour) {
	if (checkedSurveyMap[id] == null) {
		checkedSurveyMap[id] = true;
		setDatasets(id, true);
		if (colour == true) {
			changeColour(id, true);
		}	
	} else if (checkedSurveyMap[id] == true) {
		checkedSurveyMap[id] = false;
		//set all the individual datasets to false
		setDatasets(id, false);
		if (colour == true) {
			changeColour(id, false);
		}
	} else {
		checkedSurveyMap[id] = true;
		//set all the individual datasets to true
		setDatasets(id, true);
		if (colour == true) {
			changeColour(id, true);
		}
	}

	$$('input.survey_checkbox').each(function(checkbox) { { if (Element.identify(checkbox).startsWith(id + "_") ) {checkbox.checked = checkedSurveyMap[id] }} });
	showOrHideDatasetList();
}
//set all datasets for a particular survey to true or false
function selectDatasets(checkbox, selected) {
	 checkbox.checked = selected; 
	survey_id = checkbox.identify();
	id = survey_id.split("_")[0];
	if (checkedSurveyMap[id] == null) {
		checkedSurveyMap[id] = selected;
		setDatasets(id, selected);
		changeColour(id, selected);
	} else {
		checkedSurveyMap[id] = selected;
		setDatasets(id, selected);
		changeColour(id, selected);
	}
	showOrHideDatasetList();
	//make sure the checkbox for each survey is checked or unchecked
//	$$('input.survey_checkbox').each(function(checkbox) { { if (Element.identify(checkbox).startsWith(id + "_") ) {checkbox.checked = checkedSurveyMap[id] }} });
	
}

//if a dataset is checked then show in the list of them
//above the tabs
function showOrHideDatasetList() {
	//firstly 
	var anySelected = false;
	for (var dataset_id in allDatasetsMap) {
		//in format X_Y where X is the survey id and Y the dataset id, we need to know Y to hide the correct div
		var survey_dataset_id = dataset_id.split("_");
		dataset = survey_dataset_id[1];
		if (allDatasetsMap[dataset_id] == true) {
			anySelected = true;
			$('dataset_list_' + dataset).show();
			$('dataset_list_' + dataset).setStyle({'display':'inline'});
		} else {
			$('dataset_list_' + dataset).hide();
		}
	}
	if (anySelected == true) {
		$('currently_selected_datasets').show();
	} else {
		$('currently_selected_datasets').hide();
	}
}

// If any of the surveys/datasets are selected then return true else false
function areAnyDatasetsSelected() {
	var selected = false;
	for (var dataset_id in allDatasetsMap) {
		if (allDatasetsMap[dataset_id] == true) {
			selected = true;
		}
	}
	return selected;
}

//handle back, forward browser controls and uncheck all the boxes
function uncheckAll() {
    $$('input.survey_checkbox').each(function(checkbox) {
            checkbox.checked = false;
    });
}
