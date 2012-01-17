function resizeSidebar() {
var mainContainer = $('yui-main');
var height = Element.getHeight(mainContainer);
$('sidebar').setStyle({
	height: height + 'px'
});
}