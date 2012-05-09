/**********
 * Row Expansion DataTable for YUI 2
 * Author:
 *   gelinase@yahoo-inc.com / Eric Gelinas
 *   lindalj@yahoo-inc.com / John Lindal
 * @submodule Row Expansion
 * @class YAHOO.widget.RowExpansionDataTable
 ***********/
(function(){
    var expanded_rows = [];
    var expand_done = {};
    var Dom = YAHOO.util.Dom,

        STRING_STATENAME  = 'yui_dt_state',

        CLASS_EXPANDED    = 'yui-dt-expanded',
        CLASS_COLLAPSED   = 'yui-dt-collapsed',
        CLASS_EXPANSION   = 'yui-dt-expansion',
        CLASS_LINER       = 'yui-dt-liner',

        //From YUI 3
        indexOf = function(a, val) {
            for (var i=0; i<a.length; i=i+1) {
                if (a[i] === val) {
                    return i;
                }
            }

            return -1;
        };

    /**
     * The RowExpansionDataTable class extends the DataTable class to provide
     * functionality for expanding rows to show more contextual data.
     *
     * @namespace YAHOO.widget
     * @class RowExpansionDataTable
     * @extends YAHOO.widget.DataTable
     * @constructor
     * @param elContainer {HTMLElement} Container element for the TABLE.
     * @param aColumnDefs {Object[]} Array of object literal Column definitions.
     * @param oDataSource {YAHOO.util.DataSource} DataSource instance.
     * @param oConfigs {object} (optional) Object literal of configuration values.
     */
    YAHOO.widget.VariableRowExpansionDataTable = function(elContainer,aColumnDefs,oDataSource,oConfigs) {

        YAHOO.widget.VariableRowExpansionDataTable.superclass.constructor.call(this, elContainer,aColumnDefs,oDataSource,oConfigs); 

    };

    YAHOO.lang.extend( 
        YAHOO.widget.VariableRowExpansionDataTable,
        YAHOO.widget.DataTable, 
        {

            //////////////////////////////////////////////////////////////////
            //
            // Private members
            //
            //////////////////////////////////////////////////////////////////

            /**
             * Gets state object for a specific record associated with the
             * DataTable.
             *
             * @method _getRecordState
             * @param {Mixed} record_id Record / Row / or Index id
             * @param {String} key Key to return within the state object. Default is to
             * return all as a map
             * @return {Object} State data object
             * @protected
            **/
            _getRecordState : function( record_id, key ){

                var row_data    = this.getRecord( record_id ),
                    row_state   = row_data ? row_data.getData( STRING_STATENAME ) : null,
                    state_data  = ( row_state && key ) ? row_state[ key ] : row_state;

                return state_data || {};

            },

            /**
             * Sets a value to a state object with a unique id for a record
             * which is associated with the DataTable
             *
             * @method _setRecordState
             * @param {Mixed} record_id Record / Row / or Index id
             * @param {String} key Key to use in map
             * @param {Mixed} value Value to assign to the key
             * @return {Object} State data object
             * @protected
            **/
            _setRecordState : function( record_id, key, value ){

                var row_data    = this.getRecord( record_id ).getData(),
                    merged_data = row_data[ STRING_STATENAME ] || {};

                merged_data[ key ] = value;

                this.getRecord( record_id ).setData( STRING_STATENAME, merged_data );

                return merged_data;

            },
 
            /**
             * With dynamic data, we cannot restore expanded rows because the
             * record id's are never the same.
             *
             * @method onPaginatorChangeRequest
             * @private
             */
            onPaginatorChangeRequest : function() {

                if (this.get('dynamicData')) {
                    this.collapseAllRows();
                }
                YAHOO.widget.VariableRowExpansionDataTable.superclass.onPaginatorChangeRequest.apply(this, arguments);

            },

            /**
             * With dynamic data, we cannot restore expanded rows because the
             * record id's are never the same.
             *
             * @method sortColumn
             * @private
             */
            sortColumn : function() {

                if (this.get('dynamicData')) {
                    this.collapseAllRows();
                }
                YAHOO.widget.VariableRowExpansionDataTable.superclass.sortColumn.apply(this, arguments);

            },

            /**
             * Override to work around IE6 issue.
             *
             * @method _setColumnWidth
             * @private
             */
            _setColumnWidth : function() {

                var save;
                if (this.a_rowExpansions && YAHOO.widget.DataTable._bDynStylesFallback) {
                    save = this.a_rowExpansions.slice(0);
                    this.collapseAllRows();
                }

                YAHOO.widget.VariableRowExpansionDataTable.superclass._setColumnWidth.apply(this, arguments);

                if (save) {
                    this.a_rowExpansions = save;
                    this.restoreExpandedRows();
                }

            },

            /**
             * Override to skip expanded rows.
             *
             * @method getAboveTdEl
             * @param cell {HTMLElement | String | Object} DOM element reference or string ID, or
             * object literal of syntax {record:oRecord, column:oColumn} from which to get next TD element.
             * @return {HTMLElement} Reference to next TD element, or null.
             */
            getAboveTdEl : function(cell) {
                var elCell = this.getTdEl(cell);
                if(elCell) {
                    var elPreviousRow = this.getPreviousTrEl(elCell);
                    while (Dom.hasClass(elPreviousRow, CLASS_EXPANSION)) {
                        elPreviousRow = this.getPreviousTrEl(elPreviousRow);
                    }
                    if(elPreviousRow) {
                        return elPreviousRow.cells[elCell.cellIndex];
                    }
                }
                return null;
            },

            /**
             * Override to skip expanded rows.
             *
             * @method getBelowTdEl
             * @param cell {HTMLElement | String | Object} DOM element reference or string ID, or
             * object literal of syntax {record:oRecord, column:oColumn} from which to get previous TD element.
             * @return {HTMLElement} Reference to previous TD element, or null.
             */
            getBelowTdEl : function(cell) {
                var elCell = this.getTdEl(cell);
                if(elCell) {
                    var elNextRow = this.getNextTrEl(elCell);
                    while (Dom.hasClass(elNextRow, CLASS_EXPANSION)) {
                        elNextRow = this.getNextTrEl(elNextRow);
                    }
                    if(elNextRow) {
                        return elNextRow.cells[elCell.cellIndex];
                    }
                }
                return null;
            },

            //////////////////////////////////////////////////////////////////
            //
            // Public methods
            //
            //////////////////////////////////////////////////////////////////

            /**
             * Over-ridden initAttributes method from DataTable
             *
             * @method initAttributes
             * @param {Mixed} record_id Record / Row / or Index id
             * @param {String} key Key to use in map
             * @param {Mixed} value Value to assign to the key
             * @return {Object} State data object
            **/
            initAttributes : function( oConfigs ) {

                oConfigs = oConfigs || {};

                YAHOO.widget.VariableRowExpansionDataTable.superclass.initAttributes.call( this, oConfigs );

                /**
                 * The rowExpansionTemplate attribute can accept a string
                 * template or a function. The function will receive an argument
                 * "o" with the following properties:
                 *      o.data // Record instance for the expanded row
                 *      o.liner_element // The liner DIV element of the expansion
                 *      o.row_element // The TR element of the expansion
                 *      o.state // The DataTable state object
                 *
                 * @attribute rowExpansionTemplate
                 * @type {Mixed}
                 * @default ""
                **/
                this.setAttributeConfig("rowExpansionTemplate", {
                    value: "",
                    validator: function( template ){
                        return (
                            YAHOO.lang.isString( template ) ||
                            YAHOO.lang.isFunction( template )
                        );
                    },
                    method: this.initRowExpansion
                });

            },

            /**
             * Initializes row expansion on the DataTable instance
             *
             * @method initRowExpansion
             * @param {Mixed} template a string template or function to be
             *                         called when Row is expanded
            **/
            initRowExpansion : function( template ){

                //Set subscribe restore method
                this.subscribe( 'postRenderEvent', this.onEventRestoreRowExpansion );

                //Setup template
                this.rowExpansionTemplate = template;

                //Set table level state
                this.a_rowExpansions = [];

            },

            /**
             * Toggles the expansion state of a row
             *
             * @method toggleRowExpansion
             * @param {Mixed} record_id Record / Row / or Index id
            **/
            toggleRowExpansion : function( record_id ){

                var state = this._getRecordState( record_id );

                if( state && state.expanded ){

                    this.collapseRow( record_id );

                } else {

                    this.expandRow( record_id );

                }

            },

            /**
             * Sets the expansion state of a row to expanded
             *
             * @method expandRow
             * @param {Mixed} record_id Record / Row / or Index id
             * @param {Boolean} restore will restore an exisiting state for a
             * row that has been collapsed by a non user action
             * @return {Boolean} successful
            **/
            expandRow : function( record_id, restore ){
                var thisObj = this;
                var state = this._getRecordState( record_id );

                if (state.expanded && !restore) {
                    return false;
                }

                var row_data = this.getRecord( record_id );
                if (!row_data) {
                    return false;
                }

                var row = this.getTrEl( row_data );
                if (!row || Dom.hasClass(this.getNextTrEl(row), CLASS_EXPANSION)) {
                    return false;
                }

                var new_row           = document.createElement('tr'),
                    column_length     = this.getFirstTrEl().childNodes.length,
                    expanded_data     = row_data.getData(),
                    expanded_content  = null,
                    template          = this.rowExpansionTemplate,
                    next_sibling      = Dom.getNextSibling( row );

                //Construct expanded row body
                new_row.className = CLASS_EXPANSION;
                var new_column = document.createElement( 'td' );
                new_column.colSpan = column_length;

                new_column.innerHTML = '<div class="'+ CLASS_LINER +'"></div>';
                new_row.appendChild( new_column );

                var liner_element = new_row.firstChild.firstChild;
                var retrieved_data; 

				var handleSuccess = function(o){
					if(o.responseText !== undefined){
						liner_element.innerHTML = YAHOO.lang.substitute( 
	                        o.responseText, 
	                        expanded_data
	                    );
		                newRow = Dom.insertAfter( new_row, row );

		                if (newRow.innerHTML.length) {

		                    thisObj._setRecordState( record_id, 'expanded', true );

		                    if( !restore ){

		                        thisObj.a_rowExpansions.push( thisObj.getRecord( record_id ).getId() );

		                    }

		                    Dom.removeClass( row, CLASS_COLLAPSED );
		                    Dom.addClass( row, CLASS_EXPANDED );

		                    //Fire custom event
		                    thisObj.fireEvent( "rowExpandEvent", { record_id : row_data.getId() } );
                                    Element.hide('spinner');
                                    //click on it again now if you want
                                    pos = expanded_rows.indexOf(expanded_data.id);
                                    expanded_rows.splice(pos, 1);
                                    //retrieve values and their counts - need to do it this way instead of javascript inside the partial since
                                   //it would not run it - possible yui issue?
//var csrf_meta_tag = $$('meta[name=csrf-token]')[0];
//YAHOO.util.Connect.initHeader('X-CSRF-Token', csrf_meta_tag.readAttribute('content'));
                                   YAHOO.util.Connect.initHeader("Accept", "application/json", true);
                                   var json_transaction = YAHOO.util.Connect.asyncRequest('GET', variables_url + '/values_array?id='+ expanded_data.id, json_callback, null);
		                    return true;

		                } else {
                                    Element.hide('spinner');
		                    return false;

		                }
					}
				}

				var handleFailure = function(o){
                                        //failed to retrieve data so allow user to click it again
                                        pos = expanded_rows.indexOf(expanded_data.id);
                                        expanded_rows.splice(pos, 1);
                                        Element.hide('spinner');
					if(o.responseText !== undefined){
						retrieved_data = o.responseText;
					}
				}

				var callback =
				{
				  success:handleSuccess,
				  failure: handleFailure
				};
				var handleJSONFailure = function(o){
                                        //failed to retrieve data about the values
					
				}
                                var handleJSONSuccess = function(o){
                                  var data = new google.visualization.DataTable();
                                  data.addColumn('string', 'Value');
                                  data.addColumn('number', 'Count');
                                  var number_of_vals = 0;
				  if(o.responseText !== undefined){
                                    var messages = YAHOO.lang.JSON.parse(o.responseText);
                                    for (var k in messages) {
                                     var var_id = messages[k].id;
                                     //$(var_id + "_blank_rows").insert(messages[k].number_of_blank_rows ? messages[k].number_of_blank_rows : "None");
                                     //var total_entries;
                                     //messages[k].valid_entries ? total_entries += messages[k].valid_entries : '';
                                     //messages[k].invalid_entries ? total_entries += messages[k].invalid_entries : '';
                                     //$(var_id + "_total_entries").insert(total_entries);
                                     for(var v in messages[k].value_domains) {
                                        var label = messages[k].value_domains[v].label;
                                        var value = messages[k].value_domains[v].value;
                                        var frequency;
                                        try {
                                          frequency = messages[k].value_domains[v].value_domain_statistic.frequency;
                                        label != 'N/A' ? data.addRow([label,parseInt(frequency)]) : data.addRow([value,parseInt(frequency)]);
                                        number_of_vals += 1;
                                        } catch(err) {

                                        }
                                      }
                                    }
                                  }
                                  if (number_of_vals > 20) {
                                    var chart = new google.visualization.ColumnChart($(expanded_data.id + '_frequency_count_chart_div'));
                                    chart.draw(data, {width: 500, height: 200, is3D: true});
                                  } else if (number_of_vals > 1) {
                                    var chart = new google.visualization.BarChart($(expanded_data.id + '_frequency_count_chart_div'));
                                    chart.draw(data, {width: 500, height: 200, is3D: true});
                                  }
                                }

				var json_callback =
				{
				  success:handleJSONSuccess,
				  failure: handleJSONFailure
				};
                                pos = expanded_rows.indexOf(expanded_data.id);
                                //stop multiple clicks of the expand button
                                if (pos == -1) {
                                  expanded_rows.push(expanded_data.id);
                                  expand_done[expanded_data.id] = false;
                                  //retrieve general info
//var csrf_meta_tag = $$('meta[name=csrf-token]')[0];
//YAHOO.util.Connect.initHeader('X-CSRF-Token', csrf_meta_tag.readAttribute('content'));
				  var transaction = YAHOO.util.Connect.asyncRequest('GET', surveys_url + '/expand_row?id='+ expanded_data.id, callback, null);
                                  Element.show('spinner');
                                }

            },

            /**
             * Sets the expansion state of a row to collapsed
             * @method collapseRow
             * @param {Mixed} record_id Record / Row / or Index id
             * @return {Boolean} successful
            **/
            collapseRow : function( record_id ){

                var row_data = this.getRecord( record_id ),
                    row      = Dom.get( row_data.getId() ),
                    state    = row_data.getData( STRING_STATENAME );

                if( state && state.expanded ){

                    var next_sibling = Dom.getNextSibling( row ),
                        hash_index   = indexOf( this.a_rowExpansions, this.getRecord(record_id).getId() );

                    if( Dom.hasClass( next_sibling, CLASS_EXPANSION ) ) {

                        next_sibling.parentNode.removeChild( next_sibling );
                        this.a_rowExpansions.splice( hash_index, 1 );
                        this._setRecordState( record_id, 'expanded', false );

                        Dom.addClass( row, CLASS_COLLAPSED );
                        Dom.removeClass( row, CLASS_EXPANDED );

                        //Fire custom event
                        this.fireEvent("rowCollapseEvent", { record_id : row_data.getId() } );
                        var row_id = row_data.getData().id;
                        pos = expanded_rows.indexOf(row_id);
                        expanded_rows.splice(pos, 1);
                        return true;

                    } else {

                        return false;

                    }

                }

            },

            /**
             * Collapses all expanded rows. This should be called before any
             * action where the row expansion markup would interfear with
             * normal DataTable markup handling. This method does not remove
             * exents attached during implementation. All event handlers should
             * be removed separately.
             *
             * @method collapseAllRows
            **/
            collapseAllRows : function(){

                var rows = this.a_rowExpansions;
                if (rows && rows.length > 0) {

                    for( var i = 0, l = rows.length; l > i; i++ ){

                        //Always pass 0 since collapseRow removes item from the a_rowExpansions array
                        this.collapseRow( rows[ 0 ] );

                    }
                }

                this.a_rowExpansions = [];

            },

            /**
             * Restores rows which have an expanded state but no markup. This
             * is to be called to restore row expansions after the DataTable
             * renders or the collapseAllRows is called.
             *
             * @method collapseAllRows
            **/
            restoreExpandedRows : function(){

                var expanded_rows = this.a_rowExpansions;

                if( !expanded_rows.length ){

                    return;

                }

                if( this.a_rowExpansions.length ){

                    for( var i = 0, l = expanded_rows.length; l > i; i++ ){

                        this.expandRow( expanded_rows[ i ] , true );

                    }

                }

            },

            /**
             * Abstract method which restores row expansion for subscribing to
             * the DataTable postRenderEvent.
             *
             * @method onEventRestoreRowExpansion
             * @param {Object} oArgs context of a subscribed event
            **/
            onEventRestoreRowExpansion : function( oArgs ){

                this.restoreExpandedRows();

            },

            /**
             * Abstract method which toggles row expansion for subscribing to
             * the DataTable postRenderEvent.
             *
             * @method onEventToggleRowExpansion
             * @param {Object} oArgs context of a subscribed event
            **/
            onEventToggleRowExpansion : function( oArgs ){

                if( YAHOO.util.Dom.hasClass( oArgs.target, 'yui-dt-expandablerow-trigger' ) ){

                    this.toggleRowExpansion( oArgs.target );

                }

            }

        });

    YAHOO.widget.VariableRowExpansionDataTable.formatRowExpansion = function(el, oRecord, oColumn, oData) {

        Dom.addClass( el.parentNode, "yui-dt-expandablerow-trigger" );
        el.innerHTML = '<a class="yui-dt-expandablerow-trigger-inner" href="javascript:void(0);"></a>';

    };
    
})();
