function getInitialData() {
  //json hash of the first page
  return initialResults;
}

function selectAllVariableCheckboxes(checked){
  var rs = this.variableDataTable.getRecordSet();
  len = rs.getLength();

  for (var index=0; index < len; index++) {
    rs.getRecord(index).setData('Select',checked);
    var id = rs.getRecord(index).getData().id;
    selectVariable(id);
  }  
  this.variableDataTable.render();
}
function invertAllVariableCheckboxes(){
  var rs = this.variableDataTable.getRecordSet();
  len = rs.getLength();

  for (var index=0; index < len; index++) {
    rs.getRecord(index).setData('Select',!rs.getRecord(index).getData('Select'));
    var id = rs.getRecord(index).getData().id;
    selectVariable(id);
  }  
  this.variableDataTable.render();
}

function updateTable(data) {
this.variableDataSource.liveData = data;
this.variableDataTable.getDataSource().sendRequest(null,
  {success: variableDataTable.onDataReturnInitializeTable},
  variableDataTable);
}

function createDynamicVariablesTable() {
YAHOO.util.Event.addListener(window, "load", function() {
    YAHOO.example.Basic = function() {
        // Customize request sent to server to be able to set total # of records
        var generateRequest = function(oState, oSelf) {
        // Get states or use defaults
        oState = oState || { pagination: null, sortedBy: null };
        var page = (oState.pagination) ? oState.pagination.page : 0;

        // Build custom request
        return  "page=" + page;
         };
	    var expansionFormatter  = function(el, oRecord, oColumn, oData) {
            var cell_element    = el.parentNode;

            //Set trigger
            if( oData ){ //Row is closed
                YAHOO.util.Dom.addClass( cell_element,
                    "yui-dt-expandablerow-trigger" );
            }

        };
        this.variablesURLFormatter = function(elLiner, oRecord, oColumn, oData) {
            var id = oRecord.getData().id;
            var name = oRecord.getData().name;
            elLiner.innerHTML = "<a href=\"" + variables_url + "/" + id + "\">" + name + "</a>";
        };
        // Add the custom formatter to the shortcuts
        YAHOO.widget.DataTable.Formatter.variablesFormatter = this.variablesURLFormatter;

        this.categoryURLFormatter = function(elLiner, oRecord, oColumn, oData) {
            var category = oRecord.getData().category;
            if (category != null) {
              elLiner.innerHTML = "<a onclick=\"Element.show('spinner');\" href=\"" + by_category_variables_url + "?category=" + category + "\">" + category + "</a>";
            } else {
              elLiner.innerHTML = "N/A";
            }
        };
        // Add the custom formatter to the shortcuts
        YAHOO.widget.DataTable.Formatter.categoryFormatter = this.categoryURLFormatter;

        var columnDefs = [
            { label: "", formatter: YAHOO.widget.VariableRowExpansionDataTable.formatRowExpansion},
            { key:"Select", label: "", formatter: "checkbox"},
		    { key: "name", label: "Title", formatter:"variablesFormatter", sortable: true, maxWidth: 100, minWidth: 100 },
		    { key: "description", label: "Description", sortable: true, width: 500, minWidth: 500 },
                    { key: "category", label: "Category", formatter:"categoryFormatter", sortable: true, maxWidth: 200, minWidth: 200 },
		    { key: "survey", label: "Survey", sortable: true, maxWidth: 200, minWidth: 200 },
		    { key: "year", label: "Year", sortable: true, maxWidth: 100, minWidth: 100 },
		    { key: "popularity", label: "Popularity", sortable: true, maxWidth: 100, minWidth: 100 }
		];

        this.variableDataSource = new YAHOO.util.DataSource(surveys_url + "/" + survey_id +"/show_all_variables?type=json"); 
        variableDataSource.responseType = YAHOO.util.LocalDataSource.TYPE_JSON;
        variableDataSource.responseSchema = {
            resultsList : "initialResults",
            fields: ["id","name","description","survey", "category","popularity", "year"]
        };
        var tableConfigs = {//generateRequest: generateRequest,
                            //initialRequest: getInitialData(),
                            //dynamicData: true, 
                            sortedBy : { key: "name", dir: YAHOO.widget.DataTable.CLASS_ASC }, 
                            paginator : pag, 
                            rowExpansionTemplate :'{id}'};
        var pag = new YAHOO.widget.Paginator({rowsPerPage: 50, totalRecords: initialResults.total_entries});
        this.variableDataTable = new YAHOO.widget.VariableRowExpansionDataTable("variables_table",
                columnDefs, variableDataSource, tableConfigs);
	this.variableDataTable.subscribe( 'cellClickEvent', variableDataTable.onEventToggleRowExpansion );
        return {
            oDS: variableDataSource,
            oDT: variableDataTable
        };
    }();
    this.variableDataTable.doBeforeLoadData = function(oRequest, oResponse, oPayload) {
        oPayload.totalRecords = oResponse.meta.totalRecords;
        oPayload.pagination.recordOffset = oResponse.meta.startIndex;
        return oPayload;
    };
    this.variableDataTable.subscribe("checkboxClickEvent", function(oArgs){
      var elCheckbox = oArgs.target;
      var newValue = elCheckbox.checked;
      var record = this.getRecord(elCheckbox);
      var column = this.getColumn(elCheckbox);
      record.setData(column.key,newValue); 
      var id = record.getData().id; 
        selectVariable(id);
      });
});
}
