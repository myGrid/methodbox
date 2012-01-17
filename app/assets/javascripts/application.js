// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function showTooltip(trigger, target) {
    new Tooltip(trigger, target)
}

function trimSpaces(str) {
    while ((str.length > 0) && (str.charAt(0) == ' '))
        str = str.substring(1);
    while ((str.length > 0) && (str.charAt(str.length - 1) == ' '))
        str = str.substring(0, str.length - 1);
    return str;
}

function addToolListTag(tag_id) {
    tools_autocompleter=autocompleters['tools_autocompleter']
    var index=tools_autocompleter.itemIDsToJsonArrayIDs([tag_id])[0];
    var item = new Element('a', { 
        'value': index
    });
    tools_autocompleter.addContactToList(item);
}

function addExpertiseListTag(tag_id) {
    expertise_autocompleter=autocompleters['expertise_autocompleter']
    var index=expertise_autocompleter.itemIDsToJsonArrayIDs([tag_id])[0];
    var item = new Element('a', {
        'value': index
    });
    expertise_autocompleter.addContactToList(item);
}

function addOrganismListTag(tag_id) {

    organism_autocompleter=autocompleters['organism_autocompleter']
    var index=organism_autocompleter.itemIDsToJsonArrayIDs([tag_id])[0];
    var item = new Element('a', { 
        'value': index
    });
    organism_autocompleter.addContactToList(item);
}



function checkNotInList(id,list) {
    rtn = true;

    for(var i = 0; i < list.length; i++)
        if(list[i][1] == id) {
            rtn = false;
            break;
        }

    return(rtn);
}

function clearList(name) {
    select=$(name)
    while(select.length>0) {
        select.remove(select.options[0])
    }
}

function removeChildren(name) {
	$(name).childElements().each(function(e) {
	        e.remove();
	    });
}

function subset() {
  p1 = $F('group_name')
  p2 = $F('group_info')
  // p3 = $F('people_hidden')
  p3 = $F('people_hidden')
  return $H({ x: p1, y: p2, z: p3 });
}

function showPopup(boxID) {
        var box = document.getElementById(boxID);
        if (box) {

                $(boxID).blindDown({ duration: 0.6 });
        }
}

function closePopup(boxID) {
        var box = document.getElementById(boxID);
        if (box) {
                $(boxID).blindUp({ duration: 0.6 });
        }
}

function toggleAuthorAvatarList(objectId){
    div = $('authorAvatarList'+objectId)
    link = $('authorAvatarListLink'+objectId)
    if (div.style.display == "none") { //EXPAND
      div.style.display = "";
      link.innerHTML = '(Hide)';
    }
    else { //COLLAPSE
      div.style.display = "none";
      link.innerHTML = '(Show All)';
    }
}

function checkNotEmpty(textBox) {
	if ($(textBox).value=="" || $(textBox).value=="Enter search terms") {
		alert('Please enter a search term.');
		$(textBox).focus();
		return false;
	} else if ($(textBox).value.length < 2){
		alert('Search term must be 2 or more letters.');
		$(textBox).focus();
		return false;
	} else {
		return true;
	}
}

// used by the publications expand abstract.  probably easier to do it
// the variables table way with some simple inline prototype but we can leave
// that for when we have some spare time!
// copied straight from sysmo

var fullResourceListItemExpandableText = new Array();
var truncResourceListItemExpandableText = new Array();

function expandResourceListItemExpandableText(objectId){
    link = $('expandableLink'+objectId)
    text = $('expandableText'+objectId)
    if (link.innerHTML == '(Expand)') { //EXPAND
      link.innerHTML = '(Collapse)';
      text.innerHTML = fullResourceListItemExpandableText[objectId];
    }
    else { //COLLAPSE
      link.innerHTML = '(Expand)';
      text.innerHTML = truncResourceListItemExpandableText[objectId];
    }
}
// open a browser window for each of the uris
function downloadFromNesstar (nesstarUris) {
	//nesstarUris.forEach(function(item) { window.open(item) });
	for ( var i=nesstarUris.length-1; i>=0; --i ){
		window.open(nesstarUris[i]);
	}
}

/*
 * Registers a callback which copies the csrf token into the
 * X-CSRF-Token header with each ajax request.  Necessary to 
 * work with rails applications which have fixed
 * CVE-2011-0447
*/

Ajax.Responders.register({
  onCreate: function(request) {
    var csrf_meta_tag = $$('meta[name=csrf-token]')[0];

    if (csrf_meta_tag) {
      var header = 'X-CSRF-Token',
          token = csrf_meta_tag.readAttribute('content');

      if (!request.options.requestHeaders) {
        request.options.requestHeaders = {};
      }
      request.options.requestHeaders[header] = token;
    }
  }
});


// document.observe('dom:loaded', function() {  
//      $('new-group-link').observe('click', function(event) {  
//         event.stop();  
//          Modalbox.show(this.href,  
//              {title: 'Create new group',  
//              width: 500}  
//          );  
//      });  
//  })

// Ajax.Responders.register({   
//   onCreate: function(){   
//     $('spinner').show();   
//   },   
//   onComplete: function() {   
//     if(Ajax.activeRequestCount == 0)   
//       $('spinner').hide();   
//   }   
// });

//Ajax.Base.prototype.initialize = Ajax.Base.prototype.initialize.wrap(
//   function(p, options){
//     p(options);
//     this.options.parameters = this.options.parameters || {};
//     this.options.parameters.authenticity_token = window._token || '';
//   }
//);
