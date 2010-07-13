
// europhenome-europhenome custom javascript

jQuery(document).ready(function() {
  jQuery(".europhenome-europhenome").find("td[rel^='qtip']").each( function() {
    jQuery(this).attr( "tooltip", jQuery(this).attr("title") );
    jQuery(this).attr( "title", "" );
    jQuery(this).qtip({
       content:  jQuery(this).attr("tooltip"),
       style:    { tip: "topMiddle", border: { radius: 5 }, width: 400, name: "light" },
       position: { corner: { target: "bottomMiddle", tooltip: "topMiddle" } },
       hide:     { when: 'mouseout', fixed: true }
    });
  });
  
  if ( ! jQuery.browser.msie ) {
    jQuery(".europhenome-europhenome table.europhenome-data th .user_instructions").show();
    jQuery(".europhenome-europhenome table.europhenome-data th").css({ "height": "30px", "overflow": "hidden" });
    jQuery(".europhenome-europhenome table.europhenome-data th")
      .live( "mouseover", function() { jQuery(this).css({ "height": "188px" }); })
      .live( "mouseout", function()  { jQuery(this).css({ "height": "30px" });  });
  }
  
});
