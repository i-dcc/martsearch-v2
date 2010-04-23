/**
* Commands to be fired on page load
*/
jQuery(document).ready(function() {
  setup_toggles();
  check_browser_compatibility();
  
  // Add an observer for all the returned dataset links - this 
  // will make sure that the target elment for the link is visible.
  jQuery("a.dataset_returned").live("click", function () {
    var target_id = jQuery(this).attr("href");
    if ( jQuery(target_id).parent().css("display") === "none" ) {
      jQuery(target_id).parent().show();
    }
    jQuery.scrollTo( target_id, 800 );
    return false;
  });
  
  // Add tooltips for the returned dataset links.
  jQuery(".dataset_link_bubble").each( function() {
    jQuery(this).attr( "tooltip", jQuery(this).attr("title") );
    jQuery(this).attr( "title", "" );
    jQuery(this).qtip({
      content:  jQuery(this).attr("tooltip"),
      style:    { tip: "topRight", border: { radius: 5 }, name: "light" },
      position: { corner: { target: "bottomLeft", tooltip: "topRight" } }
    });
  });
  
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

  if ( jQuery.browser.msie && parseInt(jQuery.browser.version,10) < 7 ) {
    browser     = "Internet Explorer";
    add_warning = true;
  } else if ( jQuery.browser.mozilla ) {
    var gecko_version        = jQuery.browser.version.split(".");
    var major_gecko_revision = parseFloat(gecko_version[0] + "." + gecko_version[1]);
    var minor_gecko_revision = parseInt(gecko_version[2],10);

    if ( major_gecko_revision == 1.9 ) {
      if ( minor_gecko_revision < 1 ) { hide_vertical_text = true; }
    } else if ( major_gecko_revision <= 1.8 ) {
      browser            = "the Mozilla Gecko rendering engine (used in Firefox and other browsers)";
      add_warning        = true;
      hide_vertical_text = true;
    }
  } else if ( jQuery.browser.webkit ) {
    var webkit_version = parseInt(jQuery.browser.version.split(".")[0],10);

    if ( webkit_version < 525 ) {
      browser            = "the Webkit rendering engine (used in Safari, Chrome and other browsers)";
      add_warning        = true;
      hide_vertical_text = true;
    }
  } else if ( jQuery.browser.opera ) {
    var opera_version       = jQuery.browser.version.split(".");
    var major_opera_version = parseInt(opera_version[0],10);
    var minor_opera_version = parseInt(opera_version[1],10);
    
    if ( major_opera_version == 10 ) {
      if ( minor_opera_version < 50 ) { hide_vertical_text = true; }
    } else if ( major_opera_version <= 9 ) {
      browser            = "the Opera web browser";
      add_warning        = true;
      hide_vertical_text = true;
    }
  }
  
  if ( add_warning && browser ) {
    var warning_string = 
      "<strong>WARNING:</strong> It appears that you are using an " +
      "older version of " + browser + ".  This site has been " +
      "developed and tested on the most recent versions and may not work " +
      "as expected.  Please consider upgrading your browser for a better " +
      "browsing experience.";
    
    jQuery("#browser_warnings").html( warning_string );
    jQuery("#browser_warnings").show();
  }
  
  if ( hide_vertical_text ) {
    jQuery(".vertical_text").css("display","none");
    jQuery(".sanger-phenotyping_heatmap th").css("height","auto");
  }
}
