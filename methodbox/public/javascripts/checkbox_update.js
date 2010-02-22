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
