// ikmc-idcc_targ_rep custom javascript

jQuery(".ikmc-idcc_targ_rep_allele_progress_clones_toggle").live("click", function () {
  jQuery(this).parent().parent().find(".ikmc-idcc_targ_rep_allele_progress_clones_content").slideToggle("fast");
  jQuery(this).toggleClass("toggle-open");
  jQuery(this).toggleClass("toggle-close");
});

jQuery(".ikmc-idcc_targ_rep_allele_progress_details_toggle").live("click", function () {
  jQuery(this).parent().parent().parent().parent().parent().find(".ikmc-idcc_targ_rep_allele_progress_details_content").slideToggle("fast");
  jQuery(this).toggleClass("toggle-open");
  jQuery(this).toggleClass("toggle-close");
});

jQuery(".ikmc-idcc_targ_rep_escell_qc_details_toggle").live("click", function () {
  jQuery(this).parent().parent().next("tr.ikmc-idcc_targ_rep_escell_qc_details").toggle();
  jQuery(this).toggleClass("toggle-open");
  jQuery(this).toggleClass("toggle-close");
});
 
jQuery(document).ready(function() {
  jQuery(".ikmc-idcc_targ_rep_allele_progress_clones_content").hide();
  jQuery(".ikmc-idcc_targ_rep_allele_progress_clones_toggle").removeClass("toggle-open");
  jQuery(".ikmc-idcc_targ_rep_allele_progress_clones_toggle").addClass("toggle-close");
  
  jQuery(".ikmc-idcc_targ_rep_allele_progress_details_content").hide();
  jQuery(".ikmc-idcc_targ_rep_allele_progress_details_toggle").removeClass("toggle-open");
  jQuery(".ikmc-idcc_targ_rep_allele_progress_details_toggle").addClass("toggle-close");
  
  jQuery(".ikmc-idcc_targ_rep_escell_qc_details").hide();
  jQuery(".ikmc-idcc_targ_rep_escell_qc_details_toggle").removeClass("toggle-open");
  jQuery(".ikmc-idcc_targ_rep_escell_qc_details_toggle").addClass("toggle-close");
});
