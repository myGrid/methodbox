var checkBoxSelected = new Object();

function setTrueOrFalse() {
    $$('input.variable_checkbox').each(function(checkbox) {
        if (checkbox.checked == true) {
            checkBoxSelected[checkbox.value] = true ;
        } else {
            checkBoxSelected[checkbox.value] = false;
        }

    });
}

function checkTrueOrFalse() {
    $$('input.variable_checkbox').each(function(checkbox) {
        if (checkBoxSelected[checkbox.value] == true) {
            checkbox.checked = true;
        }
    });
}

function uncheckAll() {
    $$('input.variable_checkbox').each(function(checkbox) {
            checkBoxSelected[checkbox.value] = false;
    });
}

// Set the checked status to true or false depending on what a user has previously
// clicked on.  Used by the ajax expand variable table row call
function setCheckedStatus(checkbox_id) {
	$(checkbox_id + '_checkbox').checked = checkBoxSelected[checkbox_id];
}
// If any of the checkboxes have been clicked then return true, otherwise false
function isAnythingChecked() {
	selected = false;
    $$('input.variable_checkbox').each(function(checkbox) {
        if (checkBoxSelected[checkbox.value] == true) {
            selected = true;
        }
    });
	return selected;
}