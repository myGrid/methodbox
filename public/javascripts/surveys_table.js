function selectAllSurveyCheckboxes(checked){
  var rs = this.surveyDataTable.getRecordSet();
  len = rs.getLength();

  for (var index=0; index < len; index++) {
    rs.getRecord(index).setData('Select',checked);
    var id = rs.getRecord(index).getData().id;
    selectSurvey(id);
  }  
  this.surveyDataTable.render();
}
function invertAllSurveyCheckboxes(){
  var rs = this.surveyDataTable.getRecordSet();
  len = rs.getLength();

  for (var index=0; index < len; index++) {
    rs.getRecord(index).setData('Select',!rs.getRecord(index).getData('Select'));
    var id = rs.getRecord(index).getData().id;
    selectSurvey(id);
  }  
  this.surveyDataTable.render();
}

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
            { key:"Select", label: "", formatter: "checkbox"},
		    { key: "title", label: "Title", formatter:"surveysFormatter", sortable: true, minWidth: 100, maxWidth: 100 },
		    { key: "description", label: "Description", sortable: true, minWidth: 500, maxWidth: 500 },
		    { key: "year", label: "Year", sortable: true, minWidth: 100, maxWidth: 100 },
		    { key: "type", label: "Type", sortable: true, minWidth: 100, maxWidth: 100 },
                    { key: "source", label: "Source", formatter:"sourceFormatter", sortable: true, minWidth: 100, maxWidth: 100 }
		];

        //var surveyDataSource = new YAHOO.util.LocalDataSource(survey_results);
        var surveyDataSource = new YAHOO.util.LocalDataSource(survey_results,{
        responseType : YAHOO.util.DataSource.TYPE_JSON,
        responseSchema : {
            resultsList : "results",
            fields : ["id","title","description","year","type", "source"]
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
                    }
                }
                res.results = filtered;
            }
            return res;
        }
    });

        var pag = new YAHOO.widget.Paginator({rowsPerPage: 30, totalRecords: survey_results.total_entries});
        this.surveyDataTable = new YAHOO.widget.RowExpansionDataTable("surveys_table",
                columnDefs, surveyDataSource, {caption: "List of all surveys", sortedBy : { key: "title", dir: YAHOO.widget.DataTable.CLASS_ASC }, paginator: pag, rowExpansionTemplate : '{id}' });
		this.surveyDataTable.subscribe( 'cellClickEvent',
				surveyDataTable.onEventToggleRowExpansion );
    var filterTimeout = null;
    var updateFilter  = function () {
        // Reset timeout
        filterTimeout = null;

        // Reset sort
        var state = surveyDataTable.getState();
        state.sortedBy = {key:'title', dir:YAHOO.widget.DataTable.CLASS_ASC};

        // Get filtered data
        surveyDataSource.sendRequest(YAHOO.util.Dom.get('filter').value,{
            success : surveyDataTable.onDataReturnInitializeTable,
            failure : surveyDataTable.onDataReturnInitializeTable,
            scope   : surveyDataTable,
            argument: state
        });
       var rs = surveyDataTable.getRecordSet().getRecords();
       var rerender = false;
       rs.each(function(obj) {
         var data = obj.getData();
         var title = data.title;
         obj.setData('Select',true);
         var recordSet = surveyDataTable.getRecordSet();
         len = recordSet.getLength();
         for (var index=0; index < len; index++) {
           var id = recordSet.getRecord(index).getData().id;
           if (id == data.id) {
             if (isSurveyChecked(id)) {
               //TODO: set the dataset checkboxes
               recordSet.getRecord(index).setData('Select',true);
               rerender = true;
             } else {
               recordSet.getRecord(index).setData('Select',false);
             }
           }
         }
       });
       if (rerender) {
         surveyDataTable.render();
       }
    };
    YAHOO.util.Event.on('filter','keyup',function (e) {
        clearTimeout(filterTimeout);
        setTimeout(updateFilter,600);
    });

        return {
            oDS: surveyDataSource,
            oDT: surveyDataTable
        };
    }();
    this.surveyDataTable.subscribe("checkboxClickEvent", function(oArgs){
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
