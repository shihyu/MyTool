/*
 *
 * Offline JavaScript Search
 * 	written by Marc Reichelt, http://www.marcreichelt.de/
 *
 *
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU Lesser General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *	
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU Lesser General Public License for more details.
 *	
 *	You should have received a copy of the GNU Lesser General Public License
 *	along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */



/**
 * Loads a JavaScript file.
 * 
 * @param src URL to JavaScript file.
 */
function loadJS(src) {
	var a = document.createElement('script');
	a.setAttribute('type', 'text/javascript');
	a.setAttribute('src', src + "?time=" + (new Date()).getTime());
	a.setAttribute('charset', 'UTF-8');
	document.getElementsByTagName('head')[0].appendChild(a);
}

/**
 * Replaces important HTML characters (&, ", < and >) by their entities.
 * Leaves the original string untouched.
 * 
 * @return Encoded string.
 */
if (!String.prototype.htmlspecialchars) {
	String.prototype.htmlspecialchars = function () {
		var result = this.replace(/\&/g, '&amp;');
		result = result.replace(/\"/g, '&quot;');
		result = result.replace(/\</g, '&lt;');
		result = result.replace(/\>/g, '&gt;');
		result = result.replace(/\ /g, ' ');
		
		return result;
	};
}

/**
 * Looks for duplicate entries and creates an array that contains each value only once.
 * Leaves the original array untouched.
 * 
 * @return Array without duplicate entries.
 */
if (!Array.prototype.unique) {
	Array.prototype.unique = function() {
	    var seen = {};
	    var result = [];
	    
	    for (var i = 0; i < this.length; i++) {
			var element = this[i];
			if (!seen[element]) {
				result.push(element);
				seen[element] = true;
			}
	    }
	    
	    return result;
	};
}

/**
 * Merges this array with another one.
 * E.g., the arrays [1, 2, 3, 4, 5] and [2, 4, 6, 8, 10] are merged to [2, 4].
 * Leaves the original arrays untouched.
 * 
 * @param array The array that will be merged with this array.
 * @return Merged array.
 */
if (!Array.prototype.merge) {
	Array.prototype.merge = function (array) {
		var mergedArray = [];
		
		for (var i = 0; i < this.length; i++) {
			for (var j = 0; j < array.length; j++) {
				if (this[i] == array[j]) {
					mergedArray.push(this[i]);
					break;
				}
			}
		}
		
		return mergedArray;
	};
}

/**
 * A variable that contains all GET parameters (like $_GET in PHP).
 */
var _GET = new (function() {
	var get = location.search;
	if (get == '') {
		return;
	}
	get = get.slice(1);
	get = get.substring(0, get.length - get.lastIndexOf('#'));
	var pairs = get.split('&');
	for (var i = 0; i < pairs.length; i++) {
		var pair = pairs[i].split('=');
		pair[0] = decodeURI(pair[0]);
		pair[1] = decodeURI(pair[1]);
		this[pair[0]] = pair[1];
	}
})();
