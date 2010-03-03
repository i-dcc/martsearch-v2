/**
* Commands to be fired on page load
*/
jQuery(document).ready(function() {
  // Add the toggling observers for results...
  jQuery(".dataset_title").live("click", function () {
    jQuery(this).parent().find(".dataset_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".doc_title").live("click", function () {
    jQuery(this).parent().parent().parent().parent().parent().find(".doc_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  // Add Toggling for error messages
  jQuery(".error_msg_toggle").live("click", function () {
    jQuery(this).parent().parent().find(".error_msg_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".error_msg_toggle").each( function (index) {
    jQuery(this).parent().parent().find(".error_msg_content").slideUp("fast");
    jQuery(this).addClass("toggle-open");
    jQuery(this).removeClass("toggle-close");
  });
  
  // Add prettyPhoto to anything with the property 'rel="prettyPhoto"'
  jQuery("a[rel^='prettyPhoto']").prettyPhoto({ theme: 'facebook' });
  
  // Add tablesorter to anything with the class 'tablesorter'
  jQuery("table.tablesorter").tablesorter({ widgets: ['zebra'], dateFormat: "uk" });
});
