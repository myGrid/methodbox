var datasets_checked = [];
var surveys_checked = [];
var allDatasetsMap ={};

//Add or remove a survey from the list
//of selected ones
function selectSurvey(id) {
 pos = surveys_checked.indexOf(id);
 if (pos != -1) {
   surveys_checked.splice(pos, 1);
   //uncheck all the datasets
   checkDatasets(id, false);
 } else {
   surveys_checked.push(id);
   //check all the datasets
   checkDatasets(id, true);
 }
}

//Add or remove a dataset from the list
//of selected ones
function selectDataset(id) {
 pos = datasets_checked.indexOf(id);
 if (pos != -1) {
   datasets_checked.splice(pos, 1);
   $('selected_dataset' + '_' + id).remove();
 } else {
   datasets_checked.push(id);
   var hidden_input = new Element('input',{'id': 'selected_dataset' + '_' + id,'name': 'entry_ids[]','type':'hidden'});
   hidden_input.value = id;
   $('selected_datasets').insert(hidden_input);
 }
}

//when a new dataset checkbox is created then store it
//in a map of all the surveys to their datasets
function addDatasetForSurvey(survey_id, dataset_id) {
  if (allDatasetsMap[survey_id] == null) {
    allDatasetsMap[survey_id] = [];
  }
  allDatasetsMap[survey_id].push(dataset_id);
}

//check or uncheck all the datasets for
//a particular survey
function checkDatasets(id, checked) {
  var datasets = allDatasetsMap[id];
  
  datasets.each(function(item) {
    try {
      $("dataset_checkbox_" + item).checked = checked;
    } catch (error) {
    }
  });
  //if we are unchecking then also remove them from the checked datasets list
  if (checked == false) {
    datasets.each(function(item) {
      pos = datasets_checked.indexOf(item);
      datasets_checked.splice(pos, 1);
      $('selected_dataset' + '_' + item).remove()
    });
  } else {
    datasets.each(function(item) {
      datasets_checked.push(item);
      var hidden_input = new Element('input',{'id': 'selected_dataset' + '_' + item,'name': 'entry_ids[]','type':'hidden'});
      hidden_input.value = item;
      $('selected_datasets').insert(hidden_input);
    });
  }
}

//set the checkbox for some datasets after
//an ajax table row is drawn
function setCheckedStatus(survey_id) {
  var datasets = allDatasetsMap[survey_id];
  datasets.each(function(item) {
    pos = datasets_checked.indexOf(item);
    if (pos != -1) {
      try {
      $("dataset_checkbox_" + item).checked = true;
      } catch (error) {
      }
    }
  })
}

function recheckSurveys() {
  surveys_checked.each(function(item) {
     try {
        $("dataset_checkbox_" + item).checked = checked;
      } catch (error) {
      }
  });
}
