
// htgt_targ custom javascript

jQuery(document).ready(function() {
  jQuery(".dcc_other_gene_ids_toggle").live("click", function () {
    jQuery(this).parent().find(".dcc_other_gene_ids_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".dcc_other_gene_ids_toggle").each( function (index) {
    jQuery(this).parent().find(".dcc_other_gene_ids_content").hide();
    jQuery(this).addClass("toggle-open");
    jQuery(this).removeClass("toggle-close");
  });
});
