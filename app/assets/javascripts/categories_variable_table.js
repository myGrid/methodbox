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

function createDynamicCategoryVariablesTable() {
YAHOO.util.Event.addListener(window, "load", function() {
    YAHOO.example.Basic = function() {
        // Customize request sent to server to be able to set total # of records
        var generateRequest = function(oState, oSelf) {
        // Get states or use defaults
        oState = oState || { pagination: null, sortedBy: null };
        var sort = (oState.sortedBy) ? oState.sortedBy.key : "name"; 
        var dir = (oState.sortedBy && oState.sortedBy.dir === YAHOO.widget.DataTable.CLASS_DESC) ? "desc" : "asc"; 
        var page = (oState.pagination) ? oState.pagination.page : 1;
        var requestString = "?page=" + page + "&sort=" + sort + "&dir=" + dir + "&category=" + category;
        if (typeof survey !== "undefined") {
          requestString += "&survey=" + survey
        }
        // Build custom request
        return  requestString;
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
            if (category != null && category != 'N/A') {
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
	var handleSuccess = function(o){
		if(o.responseText !== undefined){
	          return true;
                } else {
		  return false;
                }
            };
				
	var handleFailure = function(o){
                 if(o.responseText !== undefined){
                 alert('error');
                 }
            };

	var callback =
	     {
		success:handleSuccess,
		failure: handleFailure
	      };
        YAHOO.util.Connect.initHeader('Accept', 'application/json', true);
        //var transaction = YAHOO.util.Connect.asyncRequest('GET', surveys_url + "/" + survey_id + "/show_all_variables", callback, null);
        this.variableDataSource = new YAHOO.util.XHRDataSource(variables_url + "/by_category"); 
        this.variableDataSource.responseType = YAHOO.util.XHRDataSource.TYPE_JSON;
        this.variableDataSource.responseSchema = {
            resultsList : "results",
            fields: ["id","name","description","survey", "category","popularity", "year"],
            metaFields: {
              page: "page",
              totalRecords: "total_entries",
              startIndex: "start_index"
            }
        };
        var pag = new YAHOO.widget.Paginator({rowsPerPage: 50});
        var tableConfigs = {generateRequest: generateRequest,
                            initialRequest: generateRequest(),
                            dynamicData: true, 
                            sortedBy : { key: "name", dir: YAHOO.widget.DataTable.CLASS_ASC }, 
                            paginator : pag, 
                            rowExpansionTemplate :'{id}',
                            caption: "Variables with category " + category};
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
