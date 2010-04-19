/**
* Commands to be fired on page load
*/
jQuery(document).ready(function() {
  setup_toggles();
  check_browser_compatibility();
  
  // Add prettyPhoto to anything with the property 'rel="prettyPhoto"'
  jQuery("a[rel^='prettyPhoto']").prettyPhoto({ theme: 'facebook' });
  
  // Add tablesorter to anything with the class 'tablesorter'
  jQuery("table.tablesorter").tablesorter({ widgets: ['zebra'], dateFormat: "uk" });
  
  // Add the accordion effect to anything with the class 'accordion'
  jQuery(".accordion").accordion({
    collapsible: true,
    autoHeight: false,
    icons: {
      header: "ui-icon-circle-arrow-e",
      headerSelected: "ui-icon-circle-arrow-s"
    }
  });
  
  // Add font resizing buttons
  jQuery("#fontresize").fontResize();
});

function setup_toggles() {
  // Add the toggling observers for results...
  jQuery(".dataset_title").live("click", function () {
    jQuery(this).parent().find(".dataset_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".doc_title").live("click", function () {
    jQuery(this).parent().parent().parent().parent().parent().find(".doc_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  // Add Toggling for error messages
  jQuery(".error_msg_toggle").live("click", function () {
    jQuery(this).parent().parent().find(".error_msg_content").slideToggle("fast");
    jQuery(this).toggleClass("toggle-open");
    jQuery(this).toggleClass("toggle-close");
  });
  
  jQuery(".error_msg_toggle").each( function (index) {
    jQuery(this).parent().parent().find(".error_msg_content").slideUp("fast");
    jQuery(this).addClass("toggle-open");
    jQuery(this).removeClass("toggle-close");
  });
}

// Check browser versions - so we can warn users of older browsers, 
// and switch off some advanced CSS3 features...
function check_browser_compatibility() {
  var browser            = false;
  var add_warning        = false;
  var hide_vertical_text = false;

  if ( jQuery.browser.msie && jQuery.browser.version < "8" ) {
    browser     = "Internet Explorer (or are possibly using IE8 in compatibility mode)";
    add_warning = true;
  } else if ( jQuery.browser.opera && jQuery.browser.version < "10.50" ) {
    browser            = "the Opera web browser";
    add_warning        = true;
    hide_vertical_text = true;
  } else if ( jQuery.browser.mozilla && jQuery.browser.version < "1.9" ) {
    browser            = "the Mozilla Gecko rendering engine (used in Firefox and other browsers)";
    add_warning        = true;
    hide_vertical_text = true;
  } else if ( jQuery.browser.webkit && jQuery.browser.version < "525" ) {
    browser            = "the Webkit rendering engine (used in Safari, Chrome and other browsers)";
    add_warning        = true;
    hide_vertical_text = true;
  }
  
  if ( add_warning && browser ) {
    var warning_string = 
      "<strong>WARNING:</strong> It appears that you are using an " +
      "older version of " + browser + ".  This site has only been " +
      "developed and tested on the most recent versions and may not work " +
      "as expected.  Please consider upgrading your browser ";
    
    if ( jQuery.browser.msie && jQuery.browser.version < "8" ) {
      warning_string += "(or turning off compatibilty mode if you are using IE8) ";
    }
    
    warning_string += "for a more pleasant internet browsing experience.";
    
    jQuery("#browser_warnings").html( warning_string );
    jQuery("#browser_warnings").show();
  }
  
  if ( hide_vertical_text ) {
    jQuery(".vertical_text").css("display","none");
    jQuery(".sanger-phenotyping_heatmap th").css("height","auto");
  }
}

