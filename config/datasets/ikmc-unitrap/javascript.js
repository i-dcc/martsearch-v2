
// ikmc-unitrap custom javascript

jQuery(document).ready(function() {
  jQuery(".ikmc-unitrap div.unitraps_by div").hide();
  
  jQuery(".ikmc-unitrap a.unitraps_by_link").click( function() {
    var parent = jQuery(this).parentsUntil("div.dataset_content").last().parent();
    
    // Hide any existing tables...
    parent.find("div.unitraps_by div").hide();
    
    // Show the one we want...
    parent.find("div.unitraps_by div." + jQuery(this).attr("rel")).show();
    
    return false;
  });
  
});
