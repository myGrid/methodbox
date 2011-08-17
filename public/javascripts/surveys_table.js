function createSurveyTable(){
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

        this.surveysURLFormatter = function(elLiner, oRecord, oColumn, oData) {
            var id = oRecord.getData().id;
            var title = oRecord.getData().title;
            elLiner.innerHTML = "<a href=\"" + surveys_url + "/" + id + "\">" + title + "</a>";
        };
        // Add the custom formatter to the shortcuts
        YAHOO.widget.DataTable.Formatter.surveysFormatter = this.surveysURLFormatter;

        this.sourceURLFormatter = function(elLiner, oRecord, oColumn, oData) {
            var source = oRecord.getData().source;
            if (source != "methodbox") {
              elLiner.innerHTML = "<a href=\"" + source + "\">" + source + "</a>";
            } else {
              elLiner.innerHTML = "methodbox";
            }
        };
        // Add the custom formatter to the shortcuts
        YAHOO.widget.DataTable.Formatter.sourceFormatter = this.sourceURLFormatter;

        var columnDefs = [
            { label: "", formatter: YAHOO.widget.RowExpansionDataTable.formatRowExpansion},
            { label: "", formatter: "checkbox"},
		    { key: "title", label: "Title", formatter:"surveysFormatter", sortable: true, minWidth: 100, maxWidth: 100 },
		    { key: "description", label: "Description", sortable: true, minWidth: 500, maxWidth: 500 },
		    { key: "year", label: "Year", sortable: true, minWidth: 100, maxWidth: 100 },
		    { key: "type", label: "Type", sortable: true, minWidth: 100, maxWidth: 100 },
                    { key: "source", label: "Source", formatter:"sourceFormatter", sortable: true, minWidth: 100, maxWidth: 100 }
		];

        var dataSource = new YAHOO.util.LocalDataSource(results);
        dataSource.responseType = YAHOO.util.LocalDataSource.TYPE_JSON;
        dataSource.responseSchema = {
            resultsList : "results",
            fields: ["id","title","description","year","type", "source"]
        };
        var pag = new YAHOO.widget.Paginator({rowsPerPage: 30, totalRecords: results.total_entries});
        this.dataTable = new YAHOO.widget.RowExpansionDataTable("surveys_table",
                columnDefs, dataSource, {caption: "List of all surveys", sortedBy : { key: "title", dir: YAHOO.widget.DataTable.CLASS_ASC }, paginator: pag, rowExpansionTemplate :
				                    '{id}' });
		this.dataTable.subscribe( 'cellClickEvent',
				dataTable.onEventToggleRowExpansion );
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
          selectSurvey(id);
	});
});
}
