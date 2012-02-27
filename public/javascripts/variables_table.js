var pag;
var variableDataTable;

function selectVisibleVariableCheckboxes(checked) {
  var visible_records = pag.getPageRecords();
  var rs = variableDataTable.getRecordSet();
  for (var index=visible_records[0]; index < visible_records[1] + 1; index++) {
    rs.getRecord(index).setData('Select',checked);
    var id = rs.getRecord(index).getData().id;
      selectVariable(id);
  }  
  variableDataTable.render();
}
function selectAllVariableCheckboxes(checked){
  var rs = variableDataTable.getRecordSet();
  len = rs.getLength();

  for (var index=0; index < len; index++) {
    rs.getRecord(index).setData('Select',checked);
    var id = rs.getRecord(index).getData().id;
    selectVariable(id);
  }  
  variableDataTable.render();
}
function invertAllVariableCheckboxes(){
  var rs = variableDataTable.getRecordSet();
  len = rs.getLength();

  for (var index=0; index < len; index++) {
    rs.getRecord(index).setData('Select',!rs.getRecord(index).getData('Select'));
    var id = rs.getRecord(index).getData().id;
    selectVariable(id);
  }  
  variableDataTable.render();
}

function updateTable(data) {
variableDataSource.liveData = data;
variableDataTable.getDataSource().sendRequest(null,
  {success: variableDataTable.onDataReturnInitializeTable},
  variableDataTable);
}

function createTable() {
YAHOO.util.Event.addListener(window, "load", function() {
    YAHOO.example.Basic = function() {
	    var expansionFormatter  = function(el, oRecord, oColumn, oData) {
            var cell_element    = el.parentNode;

            //Set trigger
            if( oData ){ //Row is closed
                YAHOO.util.Dom.addClass( cell_element,
                    "yui-dt-expandablerow-trigger" );
            }

        };
        var variablesURLFormatter = function(elLiner, oRecord, oColumn, oData) {
            var id = oRecord.getData().id;
            var name = oRecord.getData().name;
            elLiner.innerHTML = "<a href=\"" + variables_url + "/" + id + "\">" + name + "</a>";
        };
        var datasetsURLFormatter = function(elLiner, oRecord, oColumn, oData) {
            var id = oRecord.getData().dataset_id;
            var name = oRecord.getData().dataset;
            elLiner.innerHTML = "<a href=\"" + datasets_url + "/" + id + "\">" + name + "</a>";
        };
        var surveysURLFormatter = function(elLiner, oRecord, oColumn, oData) {
            var id = oRecord.getData().survey_id;
            var name = oRecord.getData().survey;
            elLiner.innerHTML = "<a href=\"" + surveys_url + "/" + id + "\">" + name + "</a>";
        };
        // Add the custom formatter to the shortcuts
        YAHOO.widget.DataTable.Formatter.variableVariablesFormatter = variablesURLFormatter;
        YAHOO.widget.DataTable.Formatter.variableDatasetsFormatter = datasetsURLFormatter;
        YAHOO.widget.DataTable.Formatter.variableSurveysFormatter = surveysURLFormatter;

        var categoryURLFormatter = function(elLiner, oRecord, oColumn, oData) {
            var category = oRecord.getData().category;
            if (category != null && category != 'N/A') {
              elLiner.innerHTML = "<a onclick=\"Element.show('spinner');\" href=\"" + by_category_variables_url + "?category=" + category + "\">" + category + "</a>";
            } else {
              elLiner.innerHTML = "N/A";
            }
        };
        // Add the custom formatter to the shortcuts
        YAHOO.widget.DataTable.Formatter.categoryFormatter = categoryURLFormatter;

        var columnDefs = [
            { label: "", formatter: YAHOO.widget.VariableRowExpansionDataTable.formatRowExpansion},
            { key:"Select", label: "", formatter: "checkbox"},
		    { key: "name", label: "Title", formatter:"variableVariablesFormatter", sortable: true, maxWidth: 100 },
		    { key: "description", label: "Description", sortable: true, width: 300 },
                    { key: "category", label: "Category", formatter:"categoryFormatter", sortable: true, maxWidth: 200 },
		    { key: "dataset", label: dataset, formatter:"variableDatasetsFormatter", sortable: true, maxWidth: 200 },
                    { key: "survey", label: survey, formatter:"variableSurveysFormatter", sortable: true, maxWidth: 200 },
		    { key: "year", label: "Year", sortable: true, maxWidth: 100 },
		    { key: "popularity", label: "Popularity", sortable: true, maxWidth: 100 }
		];

        var variableDataSource = new YAHOO.util.LocalDataSource(results);
        variableDataSource.responseType = YAHOO.util.LocalDataSource.TYPE_JSON;
        variableDataSource.responseSchema = {
            resultsList : "results",
            fields: ["id","name","description","survey", "dataset","survey_id","dataset_id","category","popularity", "year"]
        };
//to sort the vars add this to the table config sortedBy : { key: "name", dir: YAHOO.widget.DataTable.CLASS_ASC },
        pag = new YAHOO.widget.Paginator({rowsPerPage: 50, totalRecords: results.total_entries});
        variableDataTable = new YAHOO.widget.VariableRowExpansionDataTable("variables_table",
                columnDefs, variableDataSource, { paginator : pag, rowExpansionTemplate :'{id}' });
	variableDataTable.subscribe( 'cellClickEvent', variableDataTable.onEventToggleRowExpansion );
        return {
            oDS: variableDataSource,
            oDT: variableDataTable
        };
    }();
    variableDataTable.subscribe("checkboxClickEvent", function(oArgs){
      var elCheckbox = oArgs.target;
      var newValue = elCheckbox.checked;
      var record = variableDataTable.getRecord(elCheckbox);
      var column = variableDataTable.getColumn(elCheckbox);
      record.setData(column.key,newValue); 
      var id = record.getData().id; 
        selectVariable(id);
      });
});
}
