// ikmc-kermits custom javascript

jQuery(".ikmc-kermits_qc_details_toggle").live("click", function () {
  jQuery(this).parent().parent().next("tr.ikmc-kermits_qc_details").toggle();
  jQuery(this).toggleClass("toggle-open");
  jQuery(this).toggleClass("toggle-close");
});

jQuery(document).ready(function() {
  jQuery(".ikmc-kermits_qc_details").hide();
  jQuery(".ikmc-kermits_qc_details_toggle").addClass("toggle-open");
  jQuery(".ikmc-kermits_qc_details_toggle").removeClass("toggle-close");
});