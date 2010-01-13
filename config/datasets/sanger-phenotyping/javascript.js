
// sanger-phenotyping custom javascript

jQuery(document).ready(function() {
  jQuery(".sanger-phenotyping").find("td[rel^='qtip']").each( function() {
    jQuery(this).attr( "tooltip", jQuery(this).attr("title") );
    jQuery(this).attr( "title", "" );
    jQuery(this).qtip({
       content:  jQuery(this).attr("tooltip"),
       show:     "mouseover",
       hide:     "mouseout",
       style:    { name: "dark" },
       position: { corner: { target: "topLeft", tooltip: "bottomRight" } }
    });
  });
});
