/*!
 * fontResize JavaScript 
 * http://simplersolutions.biz
 *
 * resize the font
 * 
 * LICENSE:   Creative Commons ñ Attribution required
 *
 * author    simpler solutions <info@simplersolutions.biz>
 * license   Creative Commons ñ Attribution required
 * version   CVS: $Id$
 * link      http://simplersolutions.biz
 */

/**
 * Resize the font on your page
 * 
 * @example $('#fontResizer').fontResize();
 * @desc Add the font resizer logic into node 'fontResizer'.
 * @example $('#fontResizer).fontResize({defaultLabels :'<a href="" class="decreaseFont fontresize">smaller</a><a href="" class="normalizeFont fontresize">normal</a><a href="" class="increaseFont fontresize">bigger</a>'});
 * @desc Add the font resizer logic into node 'fontResizer' and change how the html looks
 * @example $('#fontResizer').fontResize({defaultSize :'16px'});
 * @name $.cookie
 * @cat Plugins/Cookie
 * @author simplersolutions.biz
 */
(function($) {
	$.fn.fontResize = function(parms) {

		// set the options include any overrides
		var opts = $.extend({},
		$.fn.fontResize.defaults, parms);

		this.each(function() {

			// create the node with the links
			$(this).append(opts.defaultLabels);

			// if the cookie exists then use it
			if ($.cookie(opts.defaultCookieName)) {
				$.fn.fontResize.reSize(false, $.cookie(opts.defaultCookieName));
			}

			// bind increases
			$('.' + opts.defaultIncreaseClass).click(function() {
				$.fn.fontResize.reSize(true);
				return false;
			});

			// bind decreases
			$('.' + opts.defaultDecreaseClass).click(function() {
				$.fn.fontResize.reSize(false);
				return false;
			});

			// bind reset to default size
			$('.' + opts.defaultNormalizeClass).click(function() {
				$.fn.fontResize.reSize(false, opts.defaultSize);
				return false;
			});
		});
	};

	$.fn.fontResize.reSize = function(increase, absoluteValue) {

		// if setting absolute value use that rather than calculating new value
		if (absoluteValue) {
			$($.fn.fontResize.defaults.defaultTargetNode).css("font-size", absoluteValue);
			// delete the cookie if it is the default size anyway
			if (absoluteValue == $.fn.fontResize.defaults.defaultSize) {
				$.cookie($.fn.fontResize.defaults.defaultCookieName, null, $.fn.fontResize.defaults.defaultcookieParms);
			}
			return;
		}

		// calculate change factor
		var changeFactor = increase ? 1 + ($.fn.fontResize.defaults.defaultChangePercent / 100) : 1 - ($.fn.fontResize.defaults.defaultChangePercent / 100);

		// find existing target element to resize
		var nodeCurrentSize = $($.fn.fontResize.defaults.defaultTargetNode).css("font-size");

		// split out the numeric element
		var numericPart = parseInt(nodeCurrentSize);

		// if we got garbage leave now
		if (isNaN(numericPart)) {
			return;
		}

		// split out the units eg %,px,em
		var unitsPart = nodeCurrentSize.replace(numericPart, "");

		// calculate new font size
		var newFontSize = Math.round(parseInt(nodeCurrentSize) * changeFactor) + unitsPart;

		// resize
		$($.fn.fontResize.defaults.defaultTargetNode).css("font-size", newFontSize);
		return $.cookie($.fn.fontResize.defaults.defaultCookieName, newFontSize, $.fn.fontResize.defaults.defaultcookieParms);

	};
})(jQuery);

/*
	 * ! Abstract defaults into properties, change if you wish note that
	 * available defaultcookieParms are { expires: n, path: '/abc', domain:
	 * 'yourdomain', secure: boolean }
	 * place function outside of closure so that it can be overriden
	 * 
	 */
$.fn.fontResize.defaults = {

	defaultTargetNode: "body",
	defaultChangePercent: 5,
	defaultSize: "11px",
	defaultLabels: '<a href="" class="decreaseFont fontresize">A-</a><a href="" class="normalizeFont fontresize">A</a><a href="" class="increaseFont fontresize">A+</a>',
	defaultDecreaseClass: "decreaseFont",
	defaultIncreaseClass: "increaseFont",
	defaultNormalizeClass: "normalizeFont",
	defaultInsertionNode: "fontResizer",
	defaultCookieName: "fontResizer",
	defaultcookieParms: {
		expires: 3,
		path: '/'
	}
};
