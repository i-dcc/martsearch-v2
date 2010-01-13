// ikmc-dcc-gene_details custom javascript

jQuery(document).ready(function() {
  jQuery(".ikmc-dcc-gene_details_other_gene_ids_toggle").live("click", function () {
    jQuery(this).parent().find(".ikmc-dcc-gene_details_other_gene_ids_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".ikmc-dcc-gene_details_other_gene_ids_toggle").each( function (index) {
    jQuery(this).parent().find(".ikmc-dcc-gene_details_other_gene_ids_content").hide();
    jQuery(this).addClass("toggle-open");
    jQuery(this).removeClass("toggle-close");
  });
});