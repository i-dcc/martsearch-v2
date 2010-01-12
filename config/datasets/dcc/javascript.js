// dcc custom javascript
 
jQuery(document).ready(function() {
  jQuery(".dcc_allele_progress_details_toggle").live("click", function () {
    jQuery(this).parent().parent().parent().parent().parent().find(".dcc_allele_progress_details_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".dcc_allele_progress_details_toggle").each( function (index) {
    jQuery(this).parent().parent().parent().parent().parent().find(".dcc_allele_progress_details_content").hide();
    jQuery(this).addClass("toggle-open");
    jQuery(this).removeClass("toggle-close");
  });
});
