var dt;

function updateTable(data) {
this.dataSource.liveData = data;
this.dataTable.getDataSource().sendRequest(null,
  {success: dataTable.onDataReturnInitializeTable},
  dataTable);
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
            if (category != null) {
              elLiner.innerHTML = "<a href=\"" + by_category_variables_url + "?category=" + category + "\">" + category + "</a>";
            } else {
              elLiner.innerHTML = "N/A";
            }
        };
        // Add the custom formatter to the shortcuts
        YAHOO.widget.DataTable.Formatter.categoryFormatter = this.categoryURLFormatter;

        var columnDefs = [
            { label: "", formatter: YAHOO.widget.VariableRowExpansionDataTable.formatRowExpansion},
            { label: "", formatter: "checkbox"},
		    { key: "name", label: "Title", formatter:"variablesFormatter", sortable: true, maxWidth: 100, minWidth: 100 },
		    { key: "description", label: "Description", sortable: true, width: 500, minWidth: 500 },
                    { key: "category", label: "Category", formatter:"categoryFormatter", sortable: true, maxWidth: 200, minWidth: 200 },
		    { key: "survey", label: "Survey", sortable: true, maxWidth: 200, minWidth: 200 },
		    { key: "year", label: "Year", sortable: true, maxWidth: 100, minWidth: 100 },
		    { key: "popularity", label: "Popularity", sortable: true, maxWidth: 100, minWidth: 100 }
		];

        this.dataSource = new YAHOO.util.LocalDataSource(results);
        dataSource.responseType = YAHOO.util.LocalDataSource.TYPE_JSON;
        dataSource.responseSchema = {
            resultsList : "results",
            fields: ["id","name","description","survey", "category","popularity", "year"]
        };

        var pag = new YAHOO.widget.Paginator({rowsPerPage: 50, totalRecords: results.total_entries});
        this.dataTable = new YAHOO.widget.VariableRowExpansionDataTable("variables_table",
                columnDefs, dataSource, {sortedBy : { key: "name", dir: YAHOO.widget.DataTable.CLASS_ASC }, paginator : pag, rowExpansionTemplate :'{id}' });
        dt = this.dataTable;
	this.dataTable.subscribe( 'cellClickEvent', dataTable.onEventToggleRowExpansion );
        return {
            oDS: dataSource,
            oDT: dataTable
        };
    }();
    this.dataTable.subscribe("checkboxClickEvent", function(oArgs){
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
