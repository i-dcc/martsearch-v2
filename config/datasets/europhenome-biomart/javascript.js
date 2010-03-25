
// europhenome-biomart custom javascript

jQuery(document).ready(function() {
  jQuery(".europhenome-biomart").find("td[rel^='qtip']").each( function() {
    jQuery(this).attr( "tooltip", jQuery(this).attr("title") );
    jQuery(this).attr( "title", "" );
    jQuery(this).qtip({
       content:  jQuery(this).attr("tooltip"),
       show:     { when: { event: "mouseover" }, solo: true },
       hide:     { when: { event: "unfocus" } },
       style:    { tip: "topMiddle", border: { radius: 5 }, width: 360, name: "light" },
       position: { corner: { target: "bottomMiddle", tooltip: "topMiddle" } }
    });
  });
});
