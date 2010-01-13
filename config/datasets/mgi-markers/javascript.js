
// mgi-markers custom javascript

jQuery(document).ready(function() {
  jQuery(".mgi-markers_toggle").live("click", function () {
    jQuery(this).parent().find(".mgi-markers_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".mgi-markers_toggle").each( function (index) {
    jQuery(this).parent().find(".mgi-markers_content").hide();
    jQuery(this).addClass("toggle-open");
    jQuery(this).removeClass("toggle-close");
  });
});