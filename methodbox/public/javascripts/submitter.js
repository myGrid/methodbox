//submitter.js for adding a hidden field when you have 2 submit_tag buttons in the same form

function submitForm(formname, button)
{
    var form = document.forms[formname];
    // form.action = 'put your url here';
    var el = document.createElement("input");
    el.type = "hidden";
    el.name = "myHiddenField";
    el.value = button;
    form.appendChild(el);
    form.submit();
}