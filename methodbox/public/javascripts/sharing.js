// SysMO: sharing.js
// based on osp.js from myExperiment


// global declarations
PRIVATE = null;
EVERYONE = null;
ALL_REGISTERED_USERS = null;
ALL_ELAB_USERS = null;
CUSTOM_PERMISSIONS_ONLY = null;
// --
DETERMINED_BY_GROUP = null;
NO_ACCESS = null;
VIEWING = null;
DOWNLOADING = null;
EDITING = null;

GET_POLICY_DEFAULTS_LINK = null;
GET_INSTITUTIONS_LINK = null;
GET_ALL_INSTITUTIONS_LINK = null;

CREATE_FAVOURITE_GROUP_LINK = null;
UPDATE_FAVOURITE_GROUP_LINK = null;

REVIEW_WORK_GROUP_LINK = null;


// declarations for autocompleters
// (IDs can be any strings - the only constraint is that they should hold unique names for each autocompleter)
var f_group_autocompleter_id = 'f_group_autocompleter';
var individual_people_autocompleter_id = 'ip_autocompleter';
var attributions_autocompleter_id = 'attributions_autocompleter';
// associative array that holds all instances of autocompleters on a page
var autocompleters = new Array();

var policy_settings = new Object();
var permissions_for_set = {};
var permission_settings = new Array();

var attribution_settings = new Array();

var receivedPolicySettings = null;
var receivedProjectInstitutions = null;

var currentFavouriteGroupSettings = {};


function init_sharing() {
    PRIVATE = parseInt($('const_private').value);
    EVERYONE = parseInt($('const_everyone').value);
    ALL_REGISTERED_USERS = parseInt($('const_all_registered_users').value);
    ALL_ELAB_USERS = parseInt($('const_all_sysmo_users').value);
    CUSTOM_PERMISSIONS_ONLY = parseInt($('const_custom_permissions_only').value);
	
    DETERMINED_BY_GROUP = parseInt($('const_determined_by_group').value);
    NO_ACCESS = parseInt($('const_no_access').value);
    VIEWING = parseInt($('const_viewing').value);
    DOWNLOADING = parseInt($('const_downloading').value);
    EDITING = parseInt($('const_editing').value);
	
    replaceFavouriteGroupRedboxActionURL();
}
	

function setSharingElementVisibility(sharing_scope)
{
    switch(sharing_scope)
    {
        case PRIVATE:
            $('include_custom_sharing_div_' + EVERYONE).hide();
            $('include_custom_sharing_div_' + ALL_REGISTERED_USERS).hide();
            $('include_custom_sharing_div_' + ALL_ELAB_USERS).hide();
            $('cb_use_whitelist').disabled = true;
            $('cb_use_blacklist').disabled = true;
            setCustomSharingDivVisibility(PRIVATE);
            break;
        case EVERYONE:
            $('include_custom_sharing_div_' + EVERYONE).show();
            $('include_custom_sharing_div_' + ALL_REGISTERED_USERS).hide();
            $('include_custom_sharing_div_' + ALL_ELAB_USERS).hide();
            $('cb_use_whitelist').disabled = false;
            $('cb_use_blacklist').disabled = false;
            setCustomSharingDivVisibility(EVERYONE);
            break;
        case ALL_REGISTERED_USERS:
            $('include_custom_sharing_div_' + EVERYONE).hide();
            $('include_custom_sharing_div_' + ALL_REGISTERED_USERS).show();
            $('include_custom_sharing_div_' + ALL_ELAB_USERS).hide();
            $('cb_use_whitelist').disabled = false;
            $('cb_use_blacklist').disabled = false;
            setCustomSharingDivVisibility(ALL_REGISTERED_USERS);
            break;
        case ALL_ELAB_USERS:
            $('include_custom_sharing_div_' + EVERYONE).hide();
            $('include_custom_sharing_div_' + ALL_REGISTERED_USERS).hide();
            $('include_custom_sharing_div_' + ALL_ELAB_USERS).show();
            $('cb_use_whitelist').disabled = false;
            $('cb_use_blacklist').disabled = false;
            setCustomSharingDivVisibility(ALL_ELAB_USERS);
            break;
        case CUSTOM_PERMISSIONS_ONLY:
            $('include_custom_sharing_div_' + EVERYONE).hide();
            $('include_custom_sharing_div_' + ALL_REGISTERED_USERS).hide();
            $('include_custom_sharing_div_' + ALL_ELAB_USERS).hide();
            $('cb_use_whitelist').disabled = false;
            $('cb_use_blacklist').disabled = false;
            setCustomSharingDivVisibility(CUSTOM_PERMISSIONS_ONLY);
            break;
        default:
		  
    }
}


function setCustomSharingDivVisibility(sharing_scope)
{
    if ((sharing_scope >= ALL_ELAB_USERS && sharing_scope <= EVERYONE && $('include_custom_sharing_'+sharing_scope).checked)
        || sharing_scope == CUSTOM_PERMISSIONS_ONLY)
        {
        $('specific_sharing').show();
    }
    else
    {
        $('specific_sharing').hide();
    }
}


function loadDefaultProjectPolicy(project_id) {
    $('policy_loading_spinner').style.display = "inline";
  
    request = new Ajax.Request(GET_POLICY_DEFAULTS_LINK,
    {
        method: 'get',
        parameters: {
            policy_type: 'default',
            entity_type: 'Project',
            entity_id: project_id
        },
        onSuccess: function(transport){
            $('policy_loading_spinner').style.display = "none";
                                 
            // "true" parameter to evalJSON() activates sanitization of input
            var data = transport.responseText.evalJSON(true);
                                 
            if (data.status == 200) {
                msg = data.found_exact_match ? 'Default policy found and loaded' : 'Couldn\'t find default policy for this Project,\nsystem defaults loaded instead.'
                alert(msg);
                                   
                receivedPolicySettings = data;
                                   
                parsePolicyJSONData(data);
                updateSharingSettings();
            }
            else {
                error_status = data.status;
                error_message = data.error
                alert('An error occurred...\n\nHTTP Status: ' + error_status + '\n' + error_message);
            }
        },
        onFailure: function(transport){
            $('policy_loading_spinner').style.display = "none";
            alert('Something went wrong, please try again...');
        }
    });

}


function parsePolicyJSONData(data) {
    // re-initialize data structures in case this is run more than one time
    policy_settings = new Object();
    permissions_for_set = {};
    permission_settings = new Array();
  
    policy_settings = data.policy
  
    for(var i = 0; i < data.permission_count; i++)
    {
        // permission IDs are present - if required
        // example: perm_id = data.permissions[i][0];
    
        // process all permissions and categorize by contributor types
        perm_settings = data.permissions[i][1];

        switch(perm_settings.contributor_type) {
            case "FavouriteGroup":
                // the only thing to check here is that the current FavouriteGroup is a whitelist/blacklist
                // (skip this group if it is; process identically to other contributor types otherwise)
                if(perm_settings.whitelist_or_blacklist)
                    continue;
          
            case "Person":
            case "WorkGroup":
            case "Project":
            case "Institution":
                addContributor(perm_settings.contributor_type, perm_settings.contributor_name, perm_settings.contributor_id, perm_settings.access_type);
                break;
            default:
        // do nothing for unknown permission types
        }
    }
}


function updateSharingSettings() {
    // ************** STANDARD SETTINGS ***************
    // reset previous settings
    $('include_custom_sharing_' + EVERYONE).checked = false;
    $('include_custom_sharing_' + ALL_REGISTERED_USERS).checked = false;
    $('include_custom_sharing_' + ALL_ELAB_USERS).checked = false;
  
    $('access_type_select_' + EVERYONE).selectedIndex = 0;
    $('access_type_select_' + ALL_REGISTERED_USERS).selectedIndex = 0;
    $('access_type_select_' + ALL_ELAB_USERS).selectedIndex = 0;
  
  
    // set all main policy settings..
    // ..sharing scope
    $('sharing_scope_' + policy_settings.sharing_scope).checked = true;
  
    // ..access_type and usage of custom permissions
    if(policy_settings.sharing_scope >= ALL_ELAB_USERS && policy_settings.sharing_scope <= EVERYONE) {
        access_type_select = $('access_type_select_' + policy_settings.sharing_scope)
        for(var i = 0; i < access_type_select.options.length; i++)
            if(access_type_select.options[i].value == policy_settings.access_type) {
                access_type_select.selectedIndex = i;
                break;
            }
    
        if(policy_settings.use_custom_sharing)
            $('include_custom_sharing_' + policy_settings.sharing_scope).checked = true;
    }
  
    // ..whitelist / blacklist settings
    $('cb_use_whitelist').checked = policy_settings.use_whitelist;
    $('cb_use_blacklist').checked = policy_settings.use_blacklist;
  
  
    // make sure that correct DIVs on the page are visible (same mechanism as if the
    // selections were made on the page, rather than from JavaScript)
    setSharingElementVisibility(policy_settings.sharing_scope);
  
  
    // ************** CUSTOM PERMISSIONS ***************
    // build custom permissions list and set relevant other options
    updateCustomSharingSettings();
}


function updateCustomSharingSettings() {
    // iterate through all categories of contributors in existing permissions
    // and build the "shared with" list
  
    var shared_with = '';
  
    for(contributor_type in permissions_for_set)
        for(var i = 0; i < permission_settings[contributor_type].length; i++) {
            shared_with += '<b>' + contributor_type + '</b>: ' + permission_settings[contributor_type][i][0]
            + '&nbsp;&nbsp;<span style="color: #5F5F5F;">('+ accessTypeTranslation(permission_settings[contributor_type][i][2]) +')</span>'
            + '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">'
            + '[<a href="" onclick="javascript:deleteContributor(\''+ contributor_type +'\', '+ permission_settings[contributor_type][i][1] +'); return(false);">remove</a>]</small><br/>';
        }
    
    // remove the last line break
    if(shared_with.length > 0) {
        shared_with = shared_with.slice(0,-5);
    }
  
  
    // update the page
    if(shared_with.length == 0) {
        $('shared_with_list').innerHTML = '<span class="none_text">No one</span>';
    }
    else {
        $('shared_with_list').innerHTML = shared_with;
    }
  
  
    // UPDATE THE FIELDS WHICH WILL BE SUBMITTED WITH THE PAGE
    $('sharing_permissions_contributor_types').value = "";
    $('sharing_permissions_values').value = "";
  
    for(contributor_type in permissions_for_set) {
        // assemble all permission data for current contributor type in a hash
        if(permission_settings[contributor_type].length > 0) {
            $('sharing_permissions_contributor_types').value += "\"" + contributor_type + "\", ";
            $('sharing_permissions_values').value += "\"" + contributor_type + "\"" + ": {"
	    
            for(var i = 0; i < permission_settings[contributor_type].length; i++) {
                $('sharing_permissions_values').value += permission_settings[contributor_type][i][1] + ": {\"access_type\": " + permission_settings[contributor_type][i][2] + "}, ";
            }
	    
            // "-2" in slice() required to remove the last joining comma and space from hash
            $('sharing_permissions_values').value = $('sharing_permissions_values').value.slice(0,-2);
            $('sharing_permissions_values').value += "}, ";
        }
    }
  
    // "-2" in slice() required to remove the last joining comma and space from arrays
    $('sharing_permissions_values').value = "{" + $('sharing_permissions_values').value.slice(0,-2) + "}";
    $('sharing_permissions_contributor_types').value = "[" + $('sharing_permissions_contributor_types').value.slice(0,-2) + "]";
}


function accessTypeTranslation(access_type) {
    txt = '';
  
    switch(access_type) {
        case DETERMINED_BY_GROUP:
            txt = 'individual access rights for each member';
            break;
        case NO_ACCESS:
            txt = 'no access';
            break;
        case VIEWING:
            txt = 'viewing only';
            break;
        case DOWNLOADING:
            txt = 'viewing and downloading only';
            break;
        case EDITING:
            txt = 'viewing, downloading and editing';
            break;
    }
  
    return(txt);
}


// removes a contributor from "shared with" list and updates the displayed list
function deleteContributor(contributor_type, contributor_id) {
    // update the index list (decrement count of the elements of 'contributor_type' type);
    // (the key can stay there, even if the count goes down to zero)
    permissions_for_set[contributor_type]--;
  
    // remove the actual record for the contributor
    for(var i = 0; i < permission_settings[contributor_type].length; i++)
        if(permission_settings[contributor_type][i][1] == contributor_id) {
            permission_settings[contributor_type].splice(i, 1);
            break;
        }
  
    // update the page
    updateCustomSharingSettings();
}


// adds a contributor to "shared with" list and updates the displayed list
function addContributor(contributor_type, contributor_name, contributor_id, access_type) {
    new_entry = true;
  
    // check if such (legal!) type of contributor was encoutered before --
    // if so, increment the number of occurrences of this type;
    // if not, add to set of contributor types and initialise array
    if(contributor_type in permissions_for_set)
        // such type has been seen before - check if this contributor isn't in the list yet
        if(checkContributorNotInList(contributor_type, contributor_id))
            permissions_for_set[contributor_type]++;
        else
            new_entry = false;
    else {
        permissions_for_set[contributor_type] = 0;
        permission_settings[contributor_type] = new Array();
    }
  
  
    if(new_entry) {
        // add current values into the associative array of permissions:
        // first index is the category of contributor type of the permission, the second - consecutive
        // number of occurrences of permissions for such type of contributor
        permission_settings[contributor_type][permissions_for_set[contributor_type]] =
        [contributor_name, contributor_id, access_type];
	  
        // update visible page
        updateCustomSharingSettings();
    }
    else {
        alert('The following entity was not added (already in the list):\n\n' +
            contributor_type + ': ' + contributor_name);
    }
}


function checkContributorNotInList(contributor_type, contributor_id) {
    rtn = true;
  
    if(permission_settings[contributor_type]) {
        for(var i = 0; i < permission_settings[contributor_type].length; i++)
            if(permission_settings[contributor_type][i][1] == contributor_id) {
                rtn = false;
                break;
            }
    }
  
    return(rtn);
}

// ***************  Project & Institution Selection  *****************

function updateProjectInstitutionVisibility(step_idx) {
    switch(step_idx) {
        case 1:
            $('proj_select_step_1').className = "note_text";
            $('proj_select_step_2').className = "note_text_disabled";
            $('proj_select_step_3').className = "note_text_disabled";
      
            $('proj_select_step_div_1').show();
            $('proj_select_step_div_2').hide();
            $('proj_select_step_div_3').hide();
      
            $('proj_select_prev_link').hide();
            $('proj_select_next_link').show();
            $('proj_select_add_link').hide();
            break;
      
        case 2:
            $('proj_select_step_1').className = "note_text_disabled";
            $('proj_select_step_2').className = "note_text";
            $('proj_select_step_3').className = "note_text_disabled";
      
            $('proj_select_step_div_1').hide();
            $('proj_select_step_div_2').show();
            $('proj_select_step_div_3').hide();
      
            $('proj_select_prev_link').show();
            $('proj_select_next_link').show();
            $('proj_select_add_link').hide();
            break;
    
        case 3:
            $('proj_select_step_1').className = "note_text_disabled";
            $('proj_select_step_2').className = "note_text_disabled";
            $('proj_select_step_3').className = "note_text";
      
            $('proj_select_step_div_1').hide();
            $('proj_select_step_div_2').hide();
            $('proj_select_step_div_3').show();
      
            $('proj_select_prev_link').show();
            $('proj_select_next_link').hide();
            $('proj_select_add_link').show();
            break;
    }
}


function projectInstitutionStepAction(step_increment) {
    // check if not moving before Step 1 and past Step 3
    new_step_idx = parseInt($('proj_select_step_index').value) + step_increment
  
    if(new_step_idx >= 1 && new_step_idx <= 3) {
        $('proj_select_step_index').value = new_step_idx
    
        switch(new_step_idx) {
            case 1:
                updateProjectInstitutionVisibility(new_step_idx);
                break;
        
            case 2:
                if(step_increment > 0) {
                    selected_option = $('proj_project_select').options[$('proj_project_select').selectedIndex];
                    loadInstitutionsForProject(selected_option.value, selected_option.text);
                }
                else {
                    updateProjectInstitutionVisibility(new_step_idx);
                }
                break;
        
            case 3:
                replaceReviewWorkGroupURL();
                updateProjectInstitutionVisibility(new_step_idx);
                break;
        }
    }
  
}


function loadInstitutionsForProject(project_id, project_name) {
    $('institutions_loading_spinner').style.display = "inline";
  
    // choose a URL to get values from - if project wasn't selected, return all institutions
    request_url = (project_id == "") ? GET_ALL_INSTITUTIONS_LINK : GET_INSTITUTIONS_LINK;
  
    request = new Ajax.Request(request_url,
    {
        method: 'get',
        parameters: {
            id: project_id
        },
        onSuccess: function(transport){
            $('institutions_loading_spinner').style.display = "none";
                                 
            // "true" parameter to evalJSON() activates sanitization of input
            var data = transport.responseText.evalJSON(true);
                                 
            if (data.status == 200) {
                receivedProjectInstitutions = data;
                                   
                // clear any previous contents
                $('proj_institution_select').options.length = 0;
                next_index_to_use = 0;
                                   
                // if a particular project has been selected, add an option "all project"
                if(project_id != "") {
                    $('proj_institution_select').options[0] = new Option("All "+ project_name +" Project", "");
                    next_index_to_use++;
                    prefix_txt = project_name + " @ ";
                }
                else {
                    prefix_txt = '';
                }
                                   
                // fill with new contents
                for(var i = 0; i < data.institution_list.length; i++) {
                    $('proj_institution_select').options[next_index_to_use] = new Option(prefix_txt + data.institution_list[i][0], data.institution_list[i][1]);
                    next_index_to_use++;
                }
                                   
                                   
                // show relevant bits of the page
                updateProjectInstitutionVisibility(2);
            }
            else {
                error_status = data.status;
                error_message = data.error
                alert('An error occurred...\n\nHTTP Status: ' + error_status + '\n' + error_message);
            }
        },
        onFailure: function(transport){
            $('institutions_loading_spinner').style.display = "none";
            alert('Something went wrong, please try again...');
        }
    });

}


function determineProjectInstitutionSelection() {
    project_id = $('proj_project_select').options[$('proj_project_select').selectedIndex].value;
    institution_id = $('proj_institution_select').options[$('proj_institution_select').selectedIndex].value;
    access_type = parseInt($('proj_access_type_select').options[$('proj_access_type_select').selectedIndex].value);
  
    if(project_id == "") {
        add_type = "Institution";
        add_id = parseInt(institution_id);
    
        for(var i = 0; i < receivedProjectInstitutions.institution_list.length; i++)
            if(receivedProjectInstitutions.institution_list[i][1] == institution_id)
                add_name = receivedProjectInstitutions.institution_list[i][0];
    }
    else if(institution_id == "") {
        add_type = "Project";
        add_id = parseInt(project_id);
        add_name = $('proj_project_select').options[$('proj_project_select').selectedIndex].text;
    }
    else {
        institution_id = parseInt(institution_id);
    
        add_type = "WorkGroup";
        add_name = $('proj_institution_select').options[$('proj_institution_select').selectedIndex].text;
    
        for(var i = 0; i < receivedProjectInstitutions.institution_list.length; i++)
            if(receivedProjectInstitutions.institution_list[i][1] == institution_id)
                add_id = receivedProjectInstitutions.institution_list[i][2];
    }

    var result = new Array();
    result['type'] = add_type;
    result['name'] = add_name;
    result['id'] = add_id;
    result['access_type'] = access_type;
  
    return(result);
}


function addProjectInstitution() {
    var selection = determineProjectInstitutionSelection();
    add_type = selection['type'];
    add_name = selection['name'];
    add_id = selection['id'];
    access_type = selection['access_type'];
  
    // add to list and update..
    addContributor(add_type, add_name, add_id, access_type);
    // ..and reset this section to run from new
    $('proj_select_step_index').value = 1;
    $('proj_project_select').selectedIndex = 0;
    $('proj_access_type_select').selectedIndex = 0;
    updateProjectInstitutionVisibility(1);
}


function addProjectInstitutionReviewed() {
    // add the originally selected project / institution / workgroup
    originally_selected_project_institution = determineProjectInstitutionSelection();
    add_type = originally_selected_project_institution['type'];
    add_name = originally_selected_project_institution['name'];
    add_id = originally_selected_project_institution['id'];
    access_type = originally_selected_project_institution['access_type'];
    addContributor(add_type, add_name, add_id, access_type);
  
    // add individual access permissions if any of the selections for members
    // differ from originally selected access type
    search_str = 'work_group_access_rights_select_person_';
  
    all_selects = $$('select');
    for(var i = 0; i < all_selects.length; i++) {
        if(all_selects[i].id.substr(0, search_str.length) == search_str) {
            cur_access_type = parseInt(all_selects[i].value);
      
            // only add person, corresponding to current 'select' element if access type differs from original selection
            if(cur_access_type != access_type) {
                cur_id = parseInt(all_selects[i].id.substr(search_str.length));
                addContributor('Person', $('work_group_member_person_'+cur_id).innerHTML, cur_id, cur_access_type);
            }
        }
    }
  
    // reset this section to run from new
    $('proj_select_step_index').value = 1;
    $('proj_project_select').selectedIndex = 0;
    $('proj_access_type_select').selectedIndex = 0;
    updateProjectInstitutionVisibility(1);
  
    RedBox.close();
}




// ***************  Favourite Groups  *****************

function updateGroupMembers() {
    // iterate through all currently selected members and display them
  
    var group_members = '';
  
    for(id in currentFavouriteGroupSettings) {
        //alert(id + "\n" + currentFavouriteGroupSettings[id]);
        member_name = autocompleters[f_group_autocompleter_id].getValueFromJsonArray(autocompleters[f_group_autocompleter_id].itemIDsToJsonArrayIDs([id])[0], 'name');
        group_members += member_name
        + '&nbsp;<span style="color: #5F5F5F;">('+ accessTypeTranslation(currentFavouriteGroupSettings[id]) +')</span>'
        + '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:editGroupMember('+ id +', ' + currentFavouriteGroupSettings[id] + '); return(false);">edit</a>]</small>'
        + '&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:deleteGroupMember('+ id +'); return(false);">remove</a>]</small><br/>';
    }
    
    // remove the last line break
    if(group_members.length > 0) {
        group_members = group_members.slice(0,-5);
    }
  
  
    // update the page
    if(group_members.length == 0) {
        $('group_member_list').innerHTML = '<span class="none_text">No one</span>';
    }
    else {
        $('group_member_list').innerHTML = group_members;
    }
}


function addGroupMembers() {
    var selIDs = autocompleters[f_group_autocompleter_id].getRecognizedSelectedIDs();
	
    if(selIDs == "") {
        // no people to add
        alert("Please choose people to add to your favourite group!");
        return(false);
    }
    else {
        // some people to add - known that don't have duplicates
        // within the new list, but some entries in the new list
        // may replicate those in the main member list: check this
        var duplicates_found = false;
		
        for(var i = 0; i < selIDs.length; i++) {
            id = parseInt(selIDs[i]);
            if(currentFavouriteGroupSettings[id] == null)
                currentFavouriteGroupSettings[id] = parseInt($('group_access_type_select').options[$('group_access_type_select').selectedIndex].value);
            else
                duplicates_found = true;
        }
			
        if(duplicates_found) {
            alert("Some of the people added successfully, but some duplicates were encountered - these were skipped.");
        }
		
		
        // reset selection, remove all tokens from autocomplete text box and update the current selection list
        $('group_access_type_select').selectedIndex = 0;
        autocompleters[f_group_autocompleter_id].deleteAllTokens();
        updateGroupMembers();
		
        return(!duplicates_found);
    }
}


function deleteGroupMember(person_id) {
    delete currentFavouriteGroupSettings[person_id];
    updateGroupMembers();
}


function editGroupMember(person_id, access_type) {
    if(autocompleters[f_group_autocompleter_id].getRecognizedSelectedIDs() != "")
        if(! confirm('This will replace any people in the "Add members" section that were not yet added as favourite group members.\n\nAre you sure you want to proceed?'))
            return(false);
  
    // no "tokens" are present in the 'autocomplete display' field OR the user has agreed to reset their selection --
    // remove the clicked person from the list..
    delete currentFavouriteGroupSettings[person_id];
    updateGroupMembers();
  
    // ..remove any 'tokens' from 'autocomplete display' field and add the current person there (along with their selected access type)
    autocompleters[f_group_autocompleter_id].deleteAllTokens();
    autocompleters[f_group_autocompleter_id].prepopulateAutocompleterDisplayWithTokens([person_id]);
    for(var i = 0; i < $('group_access_type_select').options.length; i++)
        if(parseInt($('group_access_type_select').options[i].value) == access_type) {
            $('group_access_type_select').selectedIndex = i;
            break;
        }
}


function postFavouriteGroupData(new_group) {
    // check if the name is present
    if($('group_name').value.length == 0) {
        alert('Please specify the name for this group');
        $('group_name').focus();
        return(false);
    }
  
  
    // check if no tokens remain in the autocomplete text box
    if(autocompleters[f_group_autocompleter_id].getRecognizedSelectedIDs() != "") {
        alert('You didn\'t press "Add" link to add members from the autocomplete field');
        $('f_group_autocomplete_input').focus();
        return(false);
    }
  
  
    // check if some members are added
    var count = 0;
    for(id in currentFavouriteGroupSettings)
        count++;
  
    if(count == 0 && !confirm('There are no members in this group now.\n\nDo you want to proceed?')) {
        $('f_group_autocomplete_input').focus();
        return(false);
    }
  
  
    $('fav_group_loading_spinner').style.display = "inline";
  
    request_link = (new_group ? CREATE_FAVOURITE_GROUP_LINK : UPDATE_FAVOURITE_GROUP_LINK)
    request = new Ajax.Request(request_link,
    {
        method: 'post',
        parameters: {
            id: $('f_group_id').value,  // empty ID will be submitted on "create" action, but it doesn't make a difference
            favourite_group_name: $('group_name').value,
            favourite_group_members: Object.toJSON(currentFavouriteGroupSettings)
            },
        onSuccess: function(transport){
            $('fav_group_loading_spinner').style.display = "none";
                                 
            // "true" parameter to evalJSON() activates sanitization of input
            var data = transport.responseText.evalJSON(true);
                                 
            if (data.status == 200) {
                // reload list of favourite groups
                reloadFavouriteGroupSelect(data.favourite_groups);
                                   
                // if this is creation of a new group and need to share with it, add it to
                // "shared_with" list
                if(new_group && $('group_sharing_required').checked) {
                    addContributor(data.group_class_name, data.group_name, data.group_id, DETERMINED_BY_GROUP);
                    RedBox.close();
                    return(true);
                }
                else {
                    // if the group was in the "shared_with" list do the following:
                    // - remove / re-add current group + refresh the "shared_with" list in case any of the favourite group names have changed;
                    // - then close the modal popup window
                    if(! checkContributorNotInList(data.group_class_name, data.group_id)) {
                        deleteContributor(data.group_class_name, data.group_id);
                        addContributor(data.group_class_name, data.group_name, data.group_id, DETERMINED_BY_GROUP);
                    }
                    RedBox.close();
                    return(true);
                }
            }
            else if (data.status == 403) {
                // this value is returned by us when duplicate group name was found
                alert(data.error_message);
                $('group_name').focus();
                return(false);
            }
            else {
                error_status = data.status;
                error_message = data.error_message;
                alert('An error occurred...\n\nHTTP Status: ' + error_status + '\n' + error_message);
                return(false);
            }
        },
        onFailure: function(transport){
            $('fav_group_loading_spinner').style.display = "none";
            alert('Something went wrong, please try again...');
            return(false);
        }
    });

}


function deleteSelectedFavouriteGroup() {
    var warning_msg = 'Are you sure you want to delete this group?\n\nPlease note that it will be deleted permanently and'
    + ' any assets shared with that group will no longer be accessible to its former members';
  
    if( ! confirm(warning_msg) ) {
        return(false);
    }
  
  
    $('f_group_deleting_spinner').style.display = "inline";
  
    delete_link = $('delete_f_group_li').firstDescendant().href;
    request = new Ajax.Request(delete_link,
    {
        method: 'delete',
        parameters: {},
        onSuccess: function(transport){
            $('f_group_deleting_spinner').style.display = "none";
                                 
            // "true" parameter to evalJSON() activates sanitization of input
            var data = transport.responseText.evalJSON(true);
                                 
            if (data.status == 200) {
                // reload list of favourite groups
                reloadFavouriteGroupSelect(data.favourite_groups);
                                   
                // check if deleted group was in "shared_with" list - if so, remove it & refresh list
                if(! checkContributorNotInList(data.group_class_name, data.group_id)) {
                    deleteContributor(data.group_class_name, data.group_id);
                }
                                   
                alert('Favourite group deleted successfully');
                return(true);
            }
            else {
                error_status = data.status;
                error_message = data.error_message;
                alert('An error occurred...\n\nHTTP Status: ' + error_status + '\n' + error_message);
                return(false);
            }
        },
        onFailure: function(transport){
            $('f_group_deleting_spinner').style.display = "none";
            alert('Something went wrong, please try again...');
            return(false);
        }
    });
  
}


function reloadFavouriteGroupSelect(favourite_group_data) {
    $('favourite_group_select').options.length = 0;
    for(var i = 0; i < favourite_group_data.length; i++) {
        $('favourite_group_select').options[i] = new Option(favourite_group_data[i][0], favourite_group_data[i][1]);
    }
  
    // make sure that select box stays disabled if there are no entries after reload
    if(favourite_group_data.length > 0) {
        $('favourite_group_select').disabled = false;
        $('add_f_group_link').disabled = false;
        $('edit_f_group_li').style.display = "block";
        $('delete_f_group_li').style.display = "block";
    }
    else {
        $('favourite_group_select').options[0] = new Option("You don't have any favourite groups", "");
        $('favourite_group_select').disabled = true;
        $('add_f_group_link').disabled = true;
        $('edit_f_group_li').style.display = "none";
        $('delete_f_group_li').style.display = "none";
    }
  
  
    // when that is done, need to make sure that URLs for the currently selected group are up to date
    replaceFavouriteGroupRedboxActionURL();
  
    return(true);
}

// links to RedBox popups are very complex and need to be generated by Ruby code
// at the server side; however, for 'edit' / 'delete' links ID of the favourite
// group is required, hence a JavaScript helper is needed to add this ID to the URL
// at runtime at client side
function replaceFavouriteGroupRedboxActionURL() {
  
    // if the favourite group select box is disabled - there are no groups to select from
    if($('favourite_group_select').disabled) {
        return(false);
    }
  
  
    // **************** EDIT LINK ******************
  
    var search_str = 'parameters:';
    var search_str_id = '\'id\': \'';
    var search_str_auth_token = '\'authenticity_token=\' + encodeURIComponent(\'';
  
    var new_id = $('favourite_group_select').options[$('favourite_group_select').selectedIndex].value
  
    var parameters = {};
    parameters['id'] = new_id;
	
	
    var main_ancestor_element = $('edit_f_group_li');
    var main_element_html = main_ancestor_element.innerHTML;
    
    var first_str_index_to_replace = main_element_html.indexOf(search_str) + search_str.length;
	
    if(main_element_html.substr(first_str_index_to_replace, search_str_auth_token.length) == search_str_auth_token) {
        var authenticity_token_start_index = main_element_html.indexOf(search_str_auth_token, first_str_index_to_replace) + search_str_auth_token.length;
        parameters['authenticity_token'] = main_element_html.substr(authenticity_token_start_index, 40); // length of authenticity token is always 40 characters
		
        var last_str_index_to_replace = main_element_html.indexOf(')', authenticity_token_start_index) + 1; // 1 is the length of the ')' bracket
		
        var replace_string = main_element_html.substring(0,first_str_index_to_replace) +
        Object.toJSON(parameters).replace(/\"/g, '\'') + // replace all double quotes with single ones in the JSON representation of "parameters" hash
        main_element_html.substr(last_str_index_to_replace);
    }
    else {
        first_str_index_to_replace = main_element_html.indexOf(search_str_id) + search_str_id.length;
        var last_str_index_to_replace = main_element_html.indexOf('\'', first_str_index_to_replace); // 1 is the length of the quote
	  
	  
        var replace_string = main_element_html.substring(0,first_str_index_to_replace) +
        new_id +
        main_element_html.substr(last_str_index_to_replace);
    }
	
	
    // set the replaced HTML
    main_ancestor_element.innerHTML = replace_string;
  
  
    // **************** DELETE LINK ******************
    // read the old url and extract the base part
    var old_delete_url = $('delete_f_group_li').firstDescendant().href;
    var last_idx_to_use = old_delete_url.lastIndexOf('/') + 1; // -1 to compensate for the removed slash
    var delete_url_base = old_delete_url.substring(0, last_idx_to_use);
  
    // set the new url
    $('delete_f_group_li').firstDescendant().href = delete_url_base + parseInt($('favourite_group_select').options[$('favourite_group_select').selectedIndex].value);
  
  
    return(true);
}


// links to RedBox popups are very complex and need to be generated by Ruby code
// at the server side; however, for 'review workgroup member permissions' link ID and type of
// work group is required, hence a JavaScript helper is needed to add this ID / type to the URL
// at runtime at client side (when 'next' / 'prev' steps links are activated)
function replaceReviewWorkGroupURL() {
    // get current project / institution / workgroup selection
    proj_inst_selection = determineProjectInstitutionSelection();
	
    // remove "__type__/__id__/__access_type__" from the end of the search string
    var last_idx_to_use = REVIEW_WORK_GROUP_LINK.lastIndexOf('/');
    var search_string = REVIEW_WORK_GROUP_LINK.substring(0, last_idx_to_use);
  
    last_idx_to_use = search_string.lastIndexOf('/');
    search_string = search_string.substring(0, last_idx_to_use);
  
    last_idx_to_use = search_string.lastIndexOf('/');
    search_string = search_string.substring(0, last_idx_to_use);
	
    var parent_element = $('work_group_parent_span');
    var parent_element_html = parent_element.innerHTML;
  
    last_idx_to_use = parent_element_html.indexOf(search_string) + search_string.length;
    var last_idx_to_replace = parent_element_html.indexOf('\'', last_idx_to_use);
  
    var replace_string = parent_element_html.substring(0,last_idx_to_use) +
    '/' + proj_inst_selection['type'] + '/' + proj_inst_selection['id'] + '/' + proj_inst_selection['access_type'] +
    parent_element_html.substr(last_idx_to_replace);
	
    parent_element.innerHTML = replace_string;
}



// ***************  Individual People  *****************

function addIndividualPeople() {
    var selIDs = autocompleters[individual_people_autocompleter_id].getRecognizedSelectedIDs();
  
    if(selIDs == "") {
        // no people to add
        alert("Please choose people to share with!");
        return(false);
    }
    else {
        // some people to add - known that don't have duplicates
        // within the new list, but some entries in the new list
        // may replicate those in the main member list: check this
        var duplicates_found = false;
    
        for(var i = 0; i < selIDs.length; i++) {
            id = parseInt(selIDs[i]);
            access_type = parseInt($('individual_people_access_type_select').options[$('individual_people_access_type_select').selectedIndex].value);
            person_name = autocompleters[individual_people_autocompleter_id].getValueFromJsonArray(autocompleters[individual_people_autocompleter_id].itemIDsToJsonArrayIDs([id])[0], 'name');
            addContributor('Person', person_name, id, access_type);
        }
      
        // reset selection, remove all tokens from autocomplete text box and update the current selection list
        $('individual_people_access_type_select').selectedIndex = 0;
        autocompleters[individual_people_autocompleter_id].deleteAllTokens();
    
        return(true);
    }
}


// ***************  Whitelist / Blacklist  *****************

// will create new whitelist/blacklist (based on 'grp_name' parameter) and
// automatically cause the 'edit' action on that group afterwards
function createWhitelistBlacklist(grp_name) {
    alert('This is the first time you have requested to edit this group.\n' +
        'It doesn\'t exist yet and will be created first. After that you\n' +
        'will automatically see another screen that will allow you to add\n' +
        'people to this group.');
  
  
    $(grp_name + '_creation_spinner').style.display = "inline";
  
    request = new Ajax.Request(CREATE_FAVOURITE_GROUP_LINK,
    {
        method: 'post',
        parameters: {
            favourite_group_name: grp_name,
            favourite_group_members: "{}"
        },
        onSuccess: function(transport){
            $(grp_name + '_creation_spinner').style.display = "none";
                                 
            // "true" parameter to evalJSON() activates sanitization of input
            var data = transport.responseText.evalJSON(true);
                                 
            if (data.status == 200) {
                // whitelist/blacklist was created successfully..
                // ..replace 'create' link with 'update' one
                $(grp_name + '_create_span').style.display = "none";
                $(grp_name + '_edit_span').style.display = "inline";
                                   
                // ..set the ID of the new group to allow calling 'edit' action on it
                $(grp_name + '_group_id').value = data.group_id;
                                   
                // ..now need to show the RedBox popup to allow adding members to the new group
                editWhitelistBlacklist(grp_name);
                return(true);
            }
            else if (data.status == 403) {
                // this value is returned by us when duplicate group name was found
                alert(data.error_message);
                return(false);
            }
            else {
                error_status = data.status;
                error_message = data.error_message;
                alert('An error occurred...\n\nHTTP Status: ' + error_status + '\n' + error_message);
                return(false);
            }
        },
        onFailure: function(transport){
            $(grp_name + '_creation_spinner').style.display = "none";
            alert('Something went wrong, please try again...');
            return(false);
        }
    });
  
}


function editWhitelistBlacklist(grp_name) {
    replaceWhitelistBlacklistRedboxURL(grp_name);
    $(grp_name + '_edit_redbox').onclick();
    return(true);
}


// links to RedBox popups are very complex and need to be generated by Ruby code
// at the server side; however, for 'edit' / 'delete' links ID of the favourite
// group is required, hence a JavaScript helper is needed to add this ID to the URL
// at runtime at client side
function replaceWhitelistBlacklistRedboxURL(grp_name) {
  
    var search_str = 'parameters:';
    var search_str_id = '\'id\': \'';
    var search_str_auth_token = '\'authenticity_token=\' + encodeURIComponent(\'';
  
    var new_id = parseInt($(grp_name + '_group_id').value);
  
    var parameters = {};
    parameters['id'] = new_id;
	
	
    var main_ancestor_element = $(grp_name + '_redbox_link_div');
    var main_element_html = main_ancestor_element.innerHTML;
    
    var first_str_index_to_replace = main_element_html.indexOf(search_str) + search_str.length;
	
    if(main_element_html.substr(first_str_index_to_replace, search_str_auth_token.length) == search_str_auth_token) {
        var authenticity_token_start_index = main_element_html.indexOf(search_str_auth_token, first_str_index_to_replace) + search_str_auth_token.length;
        parameters['authenticity_token'] = main_element_html.substr(authenticity_token_start_index, 40); // length of authenticity token is always 40 characters
		
        var last_str_index_to_replace = main_element_html.indexOf(')', authenticity_token_start_index) + 1; // 1 is the length of the ')' bracket
		
        var replace_string = main_element_html.substring(0,first_str_index_to_replace) +
        Object.toJSON(parameters).replace(/\"/g, '\'') + // replace all double quotes with single ones in the JSON representation of "parameters" hash
        main_element_html.substr(last_str_index_to_replace);
	
        // set the replaced HTML
        main_ancestor_element.innerHTML = replace_string;
    }
    else {
    // do nothing, because ID of the whitelist/blacklist won't change and it was set once already
    }
  
    return(true);
}

// ***************  Resource Upload Validation  *****************

function validateSopFields(is_new_file) {
    // only make this test if that's a new SOP
    if(is_new_file) {
        if($('sop_data').value.length == 0) {
            alert("Please specify the name of the file to upload!");
            $('sop_data').focus();
            return(false);
        }
    }
  
    // other tests are applicable to both editing and creating new SOP
    if($('sop_title').value.length == 0) {
        alert("Please specify the title for the SOP!");
        $('sop_title').focus();
        return(false);
    }
  
    // check if no tokens remain in the attributions autocompleter
    // (only do this if the fold with attributions is expanded)
    if($('attributions_fold_content').style.display == "block" &&
        autocompleters[attributions_autocompleter_id].getRecognizedSelectedIDs() != "")
        {
        alert('You didn\'t press "Add" link to add items in the attributions autocomplete field.');
        $('attributions_autocomplete_input').focus();
        return(false);
    }
  
    // filename and title set - can submit
    $('sop_submit_btn').disabled = true;
    $('sop_submit_btn').value = (is_new_file ? "Uploading and Saving..." : "Updating...");
    $('sop_submit_btn').form.submit();
    return(true);
}

// ***************  Script Upload Validation  *****************

function validateScriptFields(is_new_file) {
    // only make this test if that's a new Script
    if(is_new_file) {
        if (!(/^\w/.test($('script_title').value))){
            alert("File name is not valid, please use letters, numbers or underscore only");
            $('script_title').focus();
            return(false);
        }
        if($('script_data').value.length == 0) {
            alert("Please specify the name of the file to upload!");
            $('script_data').focus();
            return(false);
        }
    }

    // other tests are applicable to both editing and creating new SOP
    if($('script_title').value.length == 0) {
        alert("Please specify the title for the Script!");
        $('script_title').focus();
        return(false);
    }

    $('script_submit_btn').disabled = true;
    $('script_submit_btn').value = (is_new_file ? "Uploading and Saving..." : "Updating...");
    $('script_submit_btn').form.submit();
    return(true);
}

function validateArchiveFields(is_new_file) {
    // only make this test if that's a new Script
    //  if(is_new_file) {
    //	  if($('_data').value.length == 0) {
    //	    alert("Please specify the name of the file to upload!");
    //	    $('script_data').focus();
    //	    return(false);
    //	  }
    //	}
    if (!(/^\w/.test($('archive_title').value))){
        alert("File name is not valid, please use letters, numbers or underscore only");
        $('archive_title').focus();
        return(false);
    }
    // other tests are applicable to both editing and creating new SOP
    if($('archive_title').value.length == 0) {
        alert("Please specify the title for the CSV Archive!");
        $('archive_title').focus();
        return(false);
    }

    $('archive_submit_btn').disabled = true;
    $('archive_submit_btn').value = (is_new_file ? "Uploading and Saving..." : "Updating...");
    $('archive_submit_btn').form.submit();
    return(true);
}

function validateArchiveFields(is_new_file) {
    // only make this test if that's a new Script
    //  if(is_new_file) {
    //	  if($('_data').value.length == 0) {
    //	    alert("Please specify the name of the file to upload!");
    //	    $('script_data').focus();
    //	    return(false);
    //	  }
    //	}
    if (!(/^\w/.test($('archive_title').value))){
        alert("File name is not valid, please use letters, numbers or underscore only");
        $('archive_title').focus();
        return(false);
    }
    // other tests are applicable to both editing and creating new SOP
    if($('archive_title').value.length == 0) {
        alert("Please specify the title for the CSV Archive!");
        $('archive_title').focus();
        return(false);
    }

    $('archive_submit_btn').disabled = true;
    $('archive_submit_btn').value = (is_new_file ? "Uploading and Saving..." : "Updating...");
    $('archive_submit_btn').form.submit();
    return(true);
}

function validateSurveySearchFields() {
    // only make this test if that's a new Model


    // other tests are applicable to both editing and creating new Model
    //  if (typeof($('entry_ids'))=="undefined") {
//    var checks = $('entry_ids');
//    var checked = false;
//    for ( i=0; i < checks.length; i++ ) {
//        if (checks[i].checked) {
//            checked = true;
//        }
//    }
//    if(checked != true) {
//        alert("Please select at least one survey to search!");
//        $('search_query').focus();
//        return(false);
//    }


//    if($('entry_ids_').checked == false) {
//        alert("Please select at least one survey to search!");
//        $('search_query').focus();
//        return(false);
//    }

    if($('survey_search_query').value.length == 0) {
        alert("Please enter a term to search for!");
        $('survey_search_query').focus();
        return(false);
    }
    //  alert("What the deuce!");
    //    $('search_query').focus();
    //    return(false);

    // search term ok and at least one survey selected - can submit

    $('search_button').form.submit();
    return(true);
}

function validateDataFileFields(is_new_file) {
    // only make this test if that's a new Model
    if(is_new_file) {
        if($('data_file_data').value.length == 0) {
            alert("Please specify the name of the file to upload!");
            $('data_file_data').focus();
            return(false);
        }
    }

    // other tests are applicable to both editing and creating new Model
    if($('data_file_title').value.length == 0) {
        alert("Please specify the title for the Data file!");
        $('data_file_title').focus();
        return(false);
    }

    // check if no tokens remain in the attributions autocompleter
    // (only do this if the fold with attributions is expanded)
    if($('attributions_fold_content').style.display == "block" &&
        autocompleters[attributions_autocompleter_id].getRecognizedSelectedIDs() != "")
        {
        alert('You didn\'t press "Add" link to add items in the attributions autocomplete field.');
        $('attributions_autocomplete_input').focus();
        return(false);
    }

    // filename and title set - can submit
    $('data_file_submit_btn').disabled = true;
    $('data_file_submit_btn').value = (is_new_file ? "Uploading and Saving..." : "Updating...");
    $('data_file_submit_btn').form.submit();
    return(true);
}

function validateSurveyFields(is_new_file) {
    // only make this test if that's a new Model
    if(is_new_file) {
        if($('survey_data').value.length == 0) {
            alert("Please specify the name of the file to upload!");
            $('survey_data').focus();
            return(false);
        }
    }

    // other tests are applicable to both editing and creating new Model
    if($('survey_title').value.length == 0) {
        alert("Please specify the title for the Survey!");
        $('survey_title').focus();
        return(false);
    }

    // check if no tokens remain in the attributions autocompleter
    // (only do this if the fold with attributions is expanded)
    if($('attributions_fold_content').style.display == "block" &&
        autocompleters[attributions_autocompleter_id].getRecognizedSelectedIDs() != "")
        {
        alert('You didn\'t press "Add" link to add items in the attributions autocomplete field.');
        $('attributions_autocomplete_input').focus();
        return(false);
    }

    // filename and title set - can submit
    $('survey_submit_btn').disabled = true;
    $('survey_submit_btn').value = (is_new_file ? "Uploading and Saving..." : "Updating...");
    $('survey_submit_btn').form.submit();
    return(true);
}


// ***************  Attributions  *****************


function updateAttributionSettings() {
    // iterate through all attributions and build the "shared with" list;
    // in the meanwhile also assemble a minimized version of the array that
    // could be posted with the form (this won't have item titles in it)
  
    var attributed_to = '';
    var attributed_to_arr = new Array();
  
    for(var i = 0; i < attribution_settings.length; i++) {
        attr_type = attribution_settings[i][0];
        attr_title = attribution_settings[i][1];
        attr_id = attribution_settings[i][2];
        attr_contributor = autocompleters[attributions_autocompleter_id].getValueFromJsonArray(autocompleters[attributions_autocompleter_id].itemIDsToJsonArrayIDs([attr_id])[0], 'contributor');
    
        attributed_to += '<b>' + attr_type + '</b>: ' + attr_title
        + "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + attr_contributor + ")</span>"
        + '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:deleteAttribution(\''+ attr_type +'\', '+ attr_id +'); return(false);">remove</a>]</small><br/>';
    
        attributed_to_arr.push([attr_type, attr_id]);
    }
  
  
    // remove the last line break
    if(attributed_to.length > 0) {
        attributed_to = attributed_to.slice(0,-5);
    }
  
  
    // update the page
    if(attributed_to.length == 0) {
        $('attributed_to_list').innerHTML = '<span class="none_text">No attributions</span>';
    }
    else {
        $('attributed_to_list').innerHTML = attributed_to;
    }
  
  
    // UPDATE THE FIELDS WHICH WILL BE SUBMITTED WITH THE PAGE
    $('attributions').value = Object.toJSON(attributed_to_arr);
}


function checkAttributionNotInList(attributable_type, attributable_id) {
    rtn = true;
  
    for(var i = 0; i < attribution_settings.length; i++)
        if(attribution_settings[i][0] == attributable_type && attribution_settings[i][2] == attributable_id) {
            rtn = false;
            break;
        }
  
    return(rtn);
}


// adds a contributor to "attributed to" list and updates the displayed list
function addAttribution(attributable_type, attributable_title, attributable_id) {
    if(checkAttributionNotInList(attributable_type, attributable_id)) {
        // add current values into the associative array of permissions:
        // first index is the category of contributor type of the permission, the second - consecutive
        // number of occurrences of permissions for such type of contributor
        attribution_settings.push([attributable_type, attributable_title, attributable_id]);
	  
        // update visible page
        updateAttributionSettings();
    }
    else {
        alert('The following entity was not added (already in the list of attributions):\n\n' +
            attributable_type + ': ' + attributable_title);
    }
}


// removes attribution from "attributed to" list and updates the displayed list
function deleteAttribution(attributable_type, attributable_id) {
    // remove the actual record for the attribution
    for(var i = 0; i < attribution_settings.length; i++)
        if(attribution_settings[i][0] == attributable_type && attribution_settings[i][2] == attributable_id) {
            attribution_settings.splice(i, 1);
            break;
        }
  
    // update the page
    updateAttributionSettings();
}


function addAttributions() {
    var selIDs = autocompleters[attributions_autocompleter_id].getRecognizedSelectedIDs();
  
    if(selIDs == "") {
        // no attributions to add
        alert("Please choose some assets to add attributions to!");
        return(false);
    }
    else {
        // some attributions to add - known that don't have duplicates
        // within the new list, but some entries in the new list
        // may replicate those in the main attribution list: this
        // will be checked by addAttribution()
    
        for(var i = 0; i < selIDs.length; i++) {
            id = parseInt(selIDs[i]);
            title = autocompleters[attributions_autocompleter_id].getValueFromJsonArray(autocompleters[attributions_autocompleter_id].itemIDsToJsonArrayIDs([id])[0], 'title');
            type = autocompleters[attributions_autocompleter_id].getValueFromJsonArray(autocompleters[attributions_autocompleter_id].itemIDsToJsonArrayIDs([id])[0], 'type');
            addAttribution(type, title, id);
        }
      
        // remove all tokens from autocomplete text box
        autocompleters[attributions_autocompleter_id].deleteAllTokens();
    
        return(true);
    }
}


// ********************************************************
