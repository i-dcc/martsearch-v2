// ikmc-dcc-trapped_products custom javascript
 
jQuery(document).ready(function() {
  jQuery(".ikmc-dcc-trapped_products_toggle").live("click", function () {
    jQuery(this).parent().parent().parent().parent().parent().find(".ikmc-dcc-trapped_products_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });

  jQuery(".ikmc-dcc-trapped_products_toggle").each( function (index) {
    jQuery(this).parent().parent().parent().parent().parent().find(".ikmc-dcc-trapped_products_content").hide();
    jQuery(this).addClass("toggle-open");
    jQuery(this).removeClass("toggle-close");
  });
});
