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
  
  /**
  * Add Toggling for error messages
  */
  
  jQuery(".error_msg_toggle").click( function () {
    jQuery(this).parent().parent().find(".error_msg_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".error_msg_toggle").each( function (index) {
    jQuery(this).parent().parent().find(".error_msg_content").slideUp("fast");
    jQuery(this).addClass("toggle-open");
    jQuery(this).removeClass("toggle-close");
  });
  
});
