function resizeSidebar() {
var mainContainer = $('main-area');
var height = Element.getHeight(mainContainer);
$('sidebar').setStyle({
	height: height + 'px'
});
}