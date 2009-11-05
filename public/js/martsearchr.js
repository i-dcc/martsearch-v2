/**
* Commands to be fired on page load
*/
jQuery(document).ready(function() {
  
  /**
  * Add the toggling observers for results...
  */
  
  jQuery(".dataset_title").live("click", function () {
    jQuery(this).parent().find(".dataset_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".doc_title").live("click", function () {
    jQuery(this).parent().find(".doc_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
});
