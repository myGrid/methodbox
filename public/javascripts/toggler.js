//toggler.js
checked = false;

var autocompleters = new Array();

function checkedAll () {
    if (checked == false){
        checked = true
    }else{
        checked = false
    }

    for (var i = 0; i < document.getElementById('tableContainer').elements.length; i++) {
        console.log('checked ' + i);
        document.getElementById('tableContainer').elements[i].checked = checked;
    }
}

function poorman_toggle(id)
{
    if($(id).visible()){
        $(id).hide()
    } else {
        $(id).show()
    }


//    var tr = document.getElementById(id);
//    if (tr==null) {
//        return;
//    }
//
//    if (tr.style.display == 'none') {
//        tr.style.display = '';
//    } else {
//        tr.style.display = 'none';
//    }
}
function poorman_changeimage(id, sMinus, sPlus)
{
    var img = document.getElementById(id);
    if (img!=null)
    {
        var bExpand = img.src.indexOf(sPlus) >= 0;
        if (!bExpand)
            img.src = sPlus;
        else
            img.src = sMinus;
    }
}


function Toggle(section)
{
    poorman_changeimage(section+'_Img', '/images/folds/unfold.png', '/images/folds/fold.png');
    poorman_toggle(section+ '_child');
}