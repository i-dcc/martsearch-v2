
// eurexpress-template custom javascript

jQuery(document).ready(function() {
  jQuery(".eurexpress-template table").tablesorter({ widgets: ['zebra'] });
  
  jQuery(".eurexpress-template .accordion").accordion({
    collapsible: true,
    active: false,
    autoHeight: false,
    icons: {
      header: "ui-icon-circle-arrow-e",
      headerSelected: "ui-icon-circle-arrow-s"
    }
  });
});
