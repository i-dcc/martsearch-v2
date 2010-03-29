// idcc-idcc_targ_rep custom javascript
 
jQuery(document).ready(function() {
  jQuery(".idcc-idcc_targ_rep_allele_progress_clones_toggle").live("click", function () {
    jQuery(this).parent().parent().find(".idcc-idcc_targ_rep_allele_progress_clones_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".idcc-idcc_targ_rep_allele_progress_details_toggle").live("click", function () {
    jQuery(this).parent().parent().parent().parent().parent().find(".idcc-idcc_targ_rep_allele_progress_details_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".idcc-idcc_targ_rep_allele_progress_clones_content").hide();
  jQuery(".idcc-idcc_targ_rep_allele_progress_clones_toggle").addClass("toggle-open");
  jQuery(".idcc-idcc_targ_rep_allele_progress_clones_toggle").removeClass("toggle-close");
  
  jQuery(".idcc-idcc_targ_rep_allele_progress_details_content").hide();
  jQuery(".idcc-idcc_targ_rep_allele_progress_details_toggle").addClass("toggle-open");
  jQuery(".idcc-idcc_targ_rep_allele_progress_details_toggle").removeClass("toggle-close");
});
