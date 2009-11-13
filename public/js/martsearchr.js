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
  
  // Phenotyping stuff...
  jQuery(".phenotyping").find("td[rel^='qtip']").each( function() {
    jQuery(this).attr( "tooltip", jQuery(this).attr("title") );
    jQuery(this).attr( "title", "" );
    jQuery(this).qtip({
       content:  jQuery(this).attr("tooltip"),
       show:     "mouseover",
       hide:     "mouseout",
       style:    { name: "dark" },
       position: { corner: { target: "topLeft", tooltip: "bottomRight" } }
    });
  });
});
