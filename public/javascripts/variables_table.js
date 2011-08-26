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

        this.variableDataSource = new YAHOO.util.LocalDataSource(results);
        variableDataSource.responseType = YAHOO.util.LocalDataSource.TYPE_JSON;
        variableDataSource.responseSchema = {
            resultsList : "results",
            fields: ["id","name","description","survey", "category","popularity", "year"]
        };

        var pag = new YAHOO.widget.Paginator({rowsPerPage: 50, totalRecords: results.total_entries});
        this.variableDataTable = new YAHOO.widget.VariableRowExpansionDataTable("variables_table",
                columnDefs, variableDataSource, {sortedBy : { key: "name", dir: YAHOO.widget.DataTable.CLASS_ASC }, paginator : pag, rowExpansionTemplate :'{id}' });
	this.variableDataTable.subscribe( 'cellClickEvent', variableDataTable.onEventToggleRowExpansion );
        return {
            oDS: variableDataSource,
            oDT: variableDataTable
        };
    }();
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
