//change hidden field values from true to false

//keep track of whether a field is true or false
hidden_values = {}

function storeHiddenFieldValue(field_id, field_value) {
  hidden_values[field_id] = field_value;
}

//set the value for a hidden field on the page. eg change a hidden
//field tag to true or false
function setHiddenFieldValue(field_id) {
   $(field_id).remove();
   var hidden_input = new Element('input',{'id': field_id,'name': field_id,'type':'hidden'});
   hidden_input.value = !hidden_values[field_id];
   $('hidden_fields').insert(hidden_input);
   hidden_values[field_id] = !hidden_values[field_id];
}

//set the value for a hidden field on the page. eg change a hidden
//field tag to true or false
function setDateValue(field_id, field_value) {
   $(field_id).remove();
   var hidden_input = new Element('input',{'id': field_id,'name': field_id,'type':'hidden'});
   hidden_input.value = field_value;
   $('hidden_fields').insert(hidden_input);
   hidden_values[field_id] = !hidden_values[field_id];
}

//set the value for a hidden field on the page. eg change a hidden
//field tag to true or false
function setLocationValue(field_id, field_value) {
   $(field_id).remove();
   var hidden_input = new Element('input',{'id': field_id,'name': field_id,'type':'hidden'});
   hidden_input.value = field_value;
   $('hidden_fields').insert(hidden_input);
   hidden_values[field_id] = !hidden_values[field_id];
}
