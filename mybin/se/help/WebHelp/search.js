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



// options
var MIN_SEARCHWORD_LENGTH = 2;
var WAIT_INTERVAL = 100;
var RESULTS_PER_PAGE = 50;
var VALID_WORD_CHARACTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";



/**
 * A category.
 * 
 * @param name Name of this category.
 */
function Category(name) {
	this.name = name;
}

/**
 * A web page.
 * 
 * @param category The category this page belongs to.
 * @param url The URL to this page (where the keywords can be found).
 * @param title Title of this page.
 * @param parent The parent page (if this is a page part).
 */
function Page(category, url, title, parent) {
	this.category = category;
	this.url = url;
	this.title = title;
	this.parent = parent;
	this.children = [];
	this.isResult = false;
	this.isTitleResult = false;
	
	this.getHTML = function() {
		var className = (this.parent == null) ? 'page' : 'page part';
		
		var result = "<p class=\"" + className + "\"><a href=\"" + this.url + "\">" + this.title.htmlspecialchars() + "</a></p>";
		for (var i = 0; i < this.children.length; i++) {
			if (this.children[i].isResult) {
				result += this.children[i].getHTML();
			}
		}
		return result;
	};
}

/**
 * Creates a new index entry.
 * 
 * @param id The id of this index.
 * @param prefix The prefix for this index (e.g. if all words of this index begin
 *  with "aa" the prefix is "aa")
 */
function Index(id, prefix) {
	this.id = id;
	this.prefix = prefix;
	this.keywords = null;
	this.isLoading = false;
	this.loaded = false;
}

/**
 * Creates a new keyword.
 * 
 * @param value Keyword value as string (e.g. "keyword").
 * @param results The results for this array (result id array, e.g. [7, 42, 145]).
 */
function K(value, results) {
	this.value = value;
	this.results = results;
}

/**
 * The search object (one single instance).
 */
var Search = new (function() {
	
	// attributes
	
	this.pages = [];
	this.indexes = [];
	this.categories = [];
	this.titleIndex = [];
	
	this.query = '';
	this.andMode = true;
	this.prefixMode = true;
	
	this.searchWords = [];
	this.searchIndexes = [];
	this.searchActive = false;
	this.totalResultCount = 0;
	this.categoryResultCount = [];
	this.titleResult = [];
	this.indexIsLoaded = false;
	
	// methods
	
	/**
	 * Executes the search (if all required index files are loaded).
	 */
	this.execute = function() {
		// check if all required indexes are loaded
		for (var i = 0; i < this.searchIndexes.length; i++) {
			if (!this.searchIndexes[i].loaded) {
				// wait
				window.setTimeout('Search.execute()', WAIT_INTERVAL);
				return;
			}
		}
		
		// wow, let's go!
		
		// look up normal results
		var finalResult = [];
		for (var i = 0; i < this.searchWords.length; i++) {
			finalResult.push(this.getSearchResult(this.searchWords[i], this.searchIndexes[i]));
		}
		finalResult = this.mergeMultipleResults(finalResult);
		
		// look up title results
		this.titleResult = [];
		for (var i = 0; i < this.searchWords.length; i++) {
			this.titleResult.push(this.getTitleResult(this.searchWords[i]));
		}
		this.titleResult = this.mergeMultipleResults(this.titleResult);
		
		
		
		// reset last search
		for (var i = 0; i < this.pages.length; i++) {
			this.pages[i].isResult = false;
			this.pages[i].isTitleResult = false;
		}
		
		// set results of this search
		for (var i = 0; i < finalResult.length; i++) {
			this.pages[finalResult[i]].isResult = true;
			
			// look if there are parents who have children which are part of
			// the result, but the parents are not
			var parent = this.pages[finalResult[i]].parent;
			if (parent != null) {
				this.pages[parent].isResult = true;
			}
		}
		for (var i = 0; i < this.titleResult.length; i++) {
			this.pages[this.titleResult[i]].isTitleResult = true;
			
			// look if there are parents who have children which are part of
			// the result, but the parents are not
			var parent = this.pages[this.titleResult[i]].parent;
			if (parent != null) {
				this.pages[parent].isTitleResult = true;
			}
		}
		
		// get total result count and result counts for categories
		this.totalResultCount = 0;
		this.categoryResultCount = [];
		for (var i = 0; i < this.categories.length; i++) {
			this.categoryResultCount.push(0);
		}
		for (var i = 0; i < this.pages.length; i++) {
			if (this.pages[i].parent == null && this.pages[i].isResult) {
				var category = this.pages[i].category;
				
				this.totalResultCount++;
				if (category != null) {
					this.categoryResultCount[category]++;
				}
			}
		}
		
		// show results
		this.displayResults(0, null);
	};
	
	/**
	 * Gets the search result for one keyword in one index.
	 * 
	 * @param word The keyword to look for.
	 * @param index Index to look in.
	 * @result A list of the results (e.g. [4, 9] if the word is in result 4 and result 9).
	 */
	this.getSearchResult = function(word, index) {
		var result = [];
		
		// check every keyword if it is a valid result
		for (var i = 0; i < index.keywords.length; i++) {
			var keyword = index.keywords[i];
			var isResult = false;
			
			if (this.prefixMode) {
				if (keyword.value.substring(0, word.length) == word) {
					isResult = true;
				}
			} else {
				if (keyword.value == word) {
					isResult = true;
				}
			}
			
			if (isResult) {
				result = result.concat(keyword.results);
			}
		}
		
		// unique the result
		return result.unique();
	};
	
	/**
	 * Gets the search result for one keyword in all titles.
	 * 
	 * @param word The keyword to look for.
	 * @result A list of the results (e.g. [4, 9] if the word is in result 4 and result 9).
	 */
	this.getTitleResult = function(word) {
		var result = [];
		
		
		// check every keyword if it is a valid result
		for (var i = 0; i < this.titleIndex.length; i++) {
			var keyword = this.titleIndex[i];
			var isResult = false;
			
			if (this.prefixMode) {
				if (keyword.value.substring(0, word.length) == word) {
					isResult = true;
				}
			} else {
				if (keyword.value == word) {
					isResult = true;
				}
			}
			
			if (isResult) {
				result = result.concat(keyword.results);
			}
		}
		
		// unique the result
		return result.unique();
	};
	
	/**
	 * Merges multiple search results.
	 * Looks for the boolean operator (AND | OR) and merges the results.
	 * E.g. the resultset [ [1, 2, 3, 4], [2, 4, 5, 7], [2, 3, 4] ] leads to the
	 * following results:
	 *     AND mode: [2, 4]
	 *     OR mode:  [1, 2, 3, 4, 5, 7]
	 * 
	 * @param multipleResults 2-dimensional array containing multiple search results.
	 * @return 1-dimensional array with the merged result.
	 */
	this.mergeMultipleResults = function(multipleResults) {
		var results = [];
		if (this.andMode) {
			// AND - results must be merged
			if (multipleResults.length > 0) {
				results = multipleResults[0];
				
				// merge
				for (var i = 1; i < multipleResults.length; i++) {
					results = results.merge(multipleResults[i]);
				}
			}
		} else {
			// OR - all results are in the final result
			for (var i = 0; i < multipleResults.length; i++) {
				results = results.concat(multipleResults[i]);
			}
			results = results.unique();
		}
		
		return results;
	};
	
	/**
	 * Displays the results.
	 * 
	 * @param resultPage Page (e.g. first of three pages) of the displayed results.
	 * @param category Category that should be shown.
	 */
	this.displayResults = function(resultPage, category) {
		var html = '';
		
		var results;
		var resultCount = 0;
		if (category == null) {
			resultCount = this.totalResultCount;
		} else {
			resultCount = this.categoryResultCount[category];
		}
		
		
		// show categories
		/*
		html += "<ul id=\"categoryList\">\n<li class=\"category\"" + ((category == null) ? " id=\"activeCategory\"" : "") + "><a href=\"#\" onclick=\"Search.displayResults(0, null); return false;\">All matches (" + this.totalResultCount + ")</a></li>";
		for (var i = 0; i < this.categories.length; i++) {
			html += "<li class=\"category\"" + ((category == i) ? " id=\"activeCategory\"" : "") + "><a href=\"#\" onclick=\"Search.displayResults(0, " + i + "); return false;\">" + this.categories[i].name.htmlspecialchars() + " (" + this.categoryResultCount[i] + ")</a></li>";
		}
		html += "</ul>\n";
		*/
		
		if (resultCount == 0) {
			html += "<p>No results found.</p>\n";
		} else {
			var startIndex = resultPage * RESULTS_PER_PAGE;
			var endIndex = Math.min((resultPage + 1) * RESULTS_PER_PAGE, resultCount) - 1;
			
			
			// show title results
			if (this.titleResult.length > 0) {
				html += "<p>Exact matches:</p>\n";
				for (var i = 0; i < this.pages.length; i++) {
					if (
						this.pages[i].parent == null &&			// page must be parent
						(category == null || this.pages[i].category == category) &&		// category has to match
						this.pages[i].isTitleResult				// page must be title result
					) {
						html += this.pages[i].getHTML();
					}
				}
			}
			
			
			html += "<p>Showing entries " + (startIndex + 1) + " to " + (endIndex + 1) + " of total " + resultCount + ":</p>\n";
			
			// look up first match of this page
			var results = [];
			for (var count = 0, i = 0; i < this.pages.length; i++) {
				if (
					this.pages[i].parent == null &&			// page must be parent
					(category == null || this.pages[i].category == category) &&		// category has to match
					this.pages[i].isResult					// page must be result
				) {
					// match!
					if (count >= startIndex && count <= endIndex) {
						results.push(this.pages[i]);
					}
					count++;
				}
			}
			
			// show matches
			for (var i = 0; i < results.length; i++) {
				html += results[i].getHTML();
			}
			
			
			html += "<p>";
			if (resultPage > 0) {
				html += " <a href=\"#\" onclick=\"Search.displayResults(" + (resultPage - 1) + ", " + category + "); return false;\">Previous</a> ";
			}
			if (endIndex < results.length - 1) {
				html += " <a href=\"#\" onclick=\"Search.displayResults(" + (resultPage + 1) + ", " + category + "); return false;\">Next</a> ";
			}
			html += "</p>\n";
		}
		
		document.getElementById('search_result').innerHTML = html;
		
		this.searchActive = false;
		document.getElementById('search_button').removeAttribute('disabled');
	};
	
	/**
	 * Start search. Function that is called out of the search page.
	 */
	this.start = function() {
		if (this.searchActive) {
			return;
		}
		
		this.searchActive = true;
		document.getElementById('search_button').setAttribute('disabled', 'disabled');
		document.getElementById('search_result').innerHTML = 'Searching...';
		
		// get search options
		this.query = document.getElementById('search_query').value.toLowerCase();
		this.andMode = document.getElementById('search_operator_and').checked;
		this.prefixMode = document.getElementById('search_mode_prefix').checked;
		
		// parse query
		this.searchWords = [];
		this.searchIndexes = [];
		
		var words = this.query.split(' ');
		
		while (words.length > 0) {
			var word = words.shift();
			
			if (this.isValidWord(word)) {
				// get index for this word
				var index = this.getIndexForKeyword(word);
				
				if (index != null) {
					// index found!
					this.searchWords.push(word);
					this.searchIndexes.push(index);
				} else {
					// no index for this word found
					//    => word is not in index!
					//       => no more search for it required
				}
			}
		}
		
		// load unloaded indexes
		for (var i = 0; i < this.searchIndexes.length; i++) {
			var index = this.searchIndexes[i];
			
			if (!index.isLoading) {
				index.isLoading = true;
				loadJS('index/' + index.id + '.js');
			}
		}
		
		// start search
		window.setTimeout('Search.execute()', 20);
	};
	
	/**
	 * Starts a search if the index is loaded and the GET-parameter 'query'
	 * contains a value.
	 */
	this.indexLoaded = function() {
		// check if index is loaded
		if (!this.indexIsLoaded) {
			// wait
			window.setTimeout('Search.indexLoaded()', WAIT_INTERVAL);
			return;
		}
		
		// add children to their parents
		for (var i = 0; i < this.pages.length; i++) {
			if (this.pages[this.pages[i].parent] != null) {
				this.pages[this.pages[i].parent].children.push(this.pages[i]);
			}
		}
		
		if (_GET['query'] != undefined) {
			// start GET search
			document.getElementById('search_query').value = _GET['query'];
			this.start();
		}
	};
	
	/**
	 * Initializes the search.
	 * This function is called when the HTML document is loaded.
	 */
	 this.initSearch = function() {
		// load main index
		loadJS('index/index.js');
		
		// set focus on query field
		document.getElementById('search_query').focus();
		
		this.indexLoaded();
	};
	
	/**
	 * Check if a word is a valid keyword.
	 * 
	 * @param s The word that is checked.
	 * @return true if the word is a valid keyword, false otherwise.
	 */
	this.isValidWord = function(s) {
		if (s.length < MIN_SEARCHWORD_LENGTH) {
			return false;
		}
		
		for (var i = 0; i < s.length; i++) {
			if (VALID_WORD_CHARACTERS.indexOf(s.charAt(i)) == -1) {
				return false;
			}
		}
		return true;
	};
	
	/**
	 * Looks up the index for a specific keyword.
	 * 
	 * @param word The word to look up.
	 * @return The index that may contain the word, null if no index could be found.
	 */
	this.getIndexForKeyword = function(word) {
		// search index
		var index = null;
		
		for (var i = 0; i < this.indexes.length; i++) {
			if (this.indexes[i].prefix == word.substring(0, this.indexes[i].prefix.length)) {
				if (index == null) {
					// first possible index found, e.g. 'a'
					index = this.indexes[i];
				} else if (this.indexes[i].prefix.length > index.prefix.length) {
					// better index found, e.g. 'aa' instead of 'a'
					index = this.indexes[i];
				}
			}
		}
		
		return index;
	}
	
})();



window.onload = function() {
	Search.initSearch();
};
