
// emma-strains custom javascript

jQuery(document).ready(function() {
  jQuery(".emma-strains-information-toggle").live("click", function () {
    jQuery( "#" + jQuery(this).attr("id").replace("toggle","content") ).toggle();
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
    return false;
  });
  
  jQuery(".emma-strains-information-toggle").each( function (index) {
    jQuery( "#" + jQuery(this).attr("id").replace("toggle","content") ).hide();
    jQuery(this).addClass("toggle-open");
    jQuery(this).removeClass("toggle-close");
  });
});
