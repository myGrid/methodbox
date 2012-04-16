var pag;
var datasetDataTable;

function selectVisibleDatasetCheckboxes(checked) {
  var visible_records = pag.getPageRecords();
  var rs = datasetDataTable.getRecordSet();
  for (var index=visible_records[0]; index < visible_records[1] + 1; index++) {
    rs.getRecord(index).setData('Select',checked);
    var id = rs.getRecord(index).getData().id;
    selectDataset(id);
  }  
  datasetDataTable.render();
}
function selectAllDatasetCheckboxes(checked){
  var rs = datasetDataTable.getRecordSet();
  len = rs.getLength();

  for (var index=0; index < len; index++) {
    rs.getRecord(index).setData('Select',checked);
    var id = rs.getRecord(index).getData().id;
    selectDataset(id);
  }  
  datasetDataTable.render();
}
function invertAllDatasetCheckboxes(){
  var rs = datasetDataTable.getRecordSet();
  len = rs.getLength();

  for (var index=0; index < len; index++) {
    rs.getRecord(index).setData('Select',!rs.getRecord(index).getData('Select'));
    var id = rs.getRecord(index).getData().id;
    selectDataset(id);
  }  
  datasetDataTable.render();
}

function createDatasetTable(){
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

        var datasetsURLFormatter = function(elLiner, oRecord, oColumn, oData) {
            var id = oRecord.getData().id;
            var title = oRecord.getData().title;
            elLiner.innerHTML = "<a href=\"" + datasets_url + "/" + id + "\">" + title + "</a>";
        };
        var surveysURLFormatter = function(elLiner, oRecord, oColumn, oData) {
            var id = oRecord.getData().survey_id;
            var title = oRecord.getData().survey;
            elLiner.innerHTML = "<a title=\"Click to view more information on this " + survey + " and its " + dataset + "s\" href=\"" + surveys_url + "/" + id + "\">" + title + "</a>";
        };
        // Add the custom formatter to the shortcuts
        YAHOO.widget.DataTable.Formatter.datasetDatasetsFormatter = datasetsURLFormatter;
        YAHOO.widget.DataTable.Formatter.datasetSurveysFormatter = surveysURLFormatter;

        var sourceURLFormatter = function(elLiner, oRecord, oColumn, oData) {
            var source = oRecord.getData().source;
            if (source != "methodbox") {
              elLiner.innerHTML = "<a href=\"" + source + "\">" + source + "</a>";
            } else {
              elLiner.innerHTML = "methodbox";
            }
        };
        // Add the custom formatter to the shortcuts
        YAHOO.widget.DataTable.Formatter.datasetSourceFormatter = sourceURLFormatter;

        var columnDefs = [
            { key:"Select", label: "", formatter: "checkbox"},
		    { key: "title", label: "Title", formatter:"datasetDatasetsFormatter", sortable: true, width: 65, resizeable: true },
		    { key: "description", label: "Description", sortable: true, width: 300, resizeable: true },
		    { key: "year", label: "Year", sortable: true, width: 50, resizeable: true },
		    { key: "survey", label: survey, formatter:"datasetSurveysFormatter", sortable: true, width: 100, resizeable: true },
		    { key: "type", label: survey_type, sortable: true, width: 75, resizeable: true },
            { key: "source", label: "Source", formatter:"datasetSourceFormatter", sortable: true, width: 150, resizeable: true }
		];

        var datasetDataSource = new YAHOO.util.LocalDataSource(dataset_results,{
        responseType : YAHOO.util.DataSource.TYPE_JSON,
        responseSchema : {
            resultsList : "results",
            fields : ["id","title","description", "survey","survey_id","year","type", "source"]
        },
        doBeforeCallback : function (req,raw,res,cb) {
            // This is the filter function
            var data     = res.results || [],
                filtered = [],
                i,l;

            if (req) {
                req = req.toLowerCase();
                for (i = 0, l = data.length; i < l; ++i) {
                    if (data[i].title.toLowerCase().indexOf(req) != -1) {
                        filtered.push(data[i]);
                    } else if (data[i].description != null && data[i].description.toLowerCase().indexOf(req) != -1) {
						filtered.push(data[i]);
					}
                }
                res.results = filtered;
            }
            return res;
        }
    });

        pag = new YAHOO.widget.Paginator({rowsPerPage: 30, totalRecords: dataset_results.total_entries});
        datasetDataTable = new YAHOO.widget.RowExpansionDataTable("datasets_table",
                columnDefs, datasetDataSource, {draggableColumns:true, caption: "List of all " + datasets_title, paginator: pag, rowExpansionTemplate : '{id}' });
		datasetDataTable.subscribe( 'cellClickEvent',
				datasetDataTable.onEventToggleRowExpansion );
    var filterTimeout = null;
    var updateFilter  = function () {
        // Reset timeout
        filterTimeout = null;

        // Reset sort
        var state = datasetDataTable.getState();
        state.sortedBy = {key:'title', dir:YAHOO.widget.DataTable.CLASS_ASC};

        // Get filtered data
        datasetDataSource.sendRequest(YAHOO.util.Dom.get('filter').value,{
            success : datasetDataTable.onDataReturnInitializeTable,
            failure : datasetDataTable.onDataReturnInitializeTable,
            scope   : datasetDataTable,
            argument: state
        });
       var rs = datasetDataTable.getRecordSet().getRecords();
       var rerender = false;
       rs.each(function(obj) {
         var data = obj.getData();
         var title = data.title;
         obj.setData('Select',true);
         var recordSet = datasetDataTable.getRecordSet();
         len = recordSet.getLength();
         for (var index=0; index < len; index++) {
           var id = recordSet.getRecord(index).getData().id;
           if (id == data.id) {
             if (isSurveyChecked(id)) {
               recordSet.getRecord(index).setData('Select',true);
               rerender = true;
             } else {
               recordSet.getRecord(index).setData('Select',false);
             }
           }
         }
       });
       if (rerender) {
         datasetDataTable.render();
       }
    };
    YAHOO.util.Event.on('filter','keyup',function (e) {
        clearTimeout(filterTimeout);
        setTimeout(updateFilter,600);
    });

        return {
            oDS: datasetDataSource,
            oDT: datasetDataTable
        };
    }();
    this.datasetDataTable.subscribe("checkboxClickEvent", function(oArgs){
      var elCheckbox = oArgs.target;
      var newValue = elCheckbox.checked;
      var record = datasetDataTable.getRecord(elCheckbox);
      var column = datasetDataTable.getColumn(elCheckbox);
      record.setData(column.key,newValue); 
      var id = record.getData().id;
      selectDataset(id);
    });
});
}
