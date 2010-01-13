
// sanger-htgt_targ custom javascript

jQuery(document).ready(function() {
  jQuery(".sanger-htgt_targ_allele_progress_clones_toggle").live("click", function () {
    jQuery(this).parent().parent().find(".sanger-htgt_targ_allele_progress_clones_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".sanger-htgt_targ_allele_progress_details_toggle").live("click", function () {
    jQuery(this).parent().parent().parent().parent().parent().find(".sanger-htgt_targ_allele_progress_details_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".sanger-htgt_targ_allele_progress_clones_toggle").each( function (index) {
    jQuery(this).parent().parent().find(".sanger-htgt_targ_allele_progress_clones_content").hide();
    jQuery(this).addClass("toggle-open");
    jQuery(this).removeClass("toggle-close");
  });

  jQuery(".sanger-htgt_targ_allele_progress_details_toggle").each( function (index) {
    jQuery(this).parent().parent().parent().parent().parent().find(".sanger-htgt_targ_allele_progress_details_content").hide();
    jQuery(this).addClass("toggle-open");
    jQuery(this).removeClass("toggle-close");
  });
  
  jQuery(".sanger-htgt_targ").find("a[rel^='prettyPhoto']").prettyPhoto();
});
