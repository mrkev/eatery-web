var Browser = require("zombie");
var assert = require("assert");
var jsdom = require("jsdom");
var Promise = require('es6-promise').Promise;


var gettable = function () {
  return new Promise(function (resolve) {

    var def_n_scripts = 29;

    // Load the page from localhost
    browser = Browser.create();
    browser.visit("http://melian3.campuslife.cornell.edu:7790/dining_menus/faces/menu_start.jspx", function (error) {
        if (error) console.trace(error);

        console.log(browser.document.URL)


        // Count script objects
        var numscripts = browser.document.querySelectorAll("script").length
        var tablehtml = browser.document.querySelector("#t2\\:\\:db").innerHTML; // Escape those got damn colons. Damn I hate Oracle.

        console.log('html', tablehtml)


        console.log(browser.document.querySelector("#navList3\\:\\:content").innerHTML);

        try {
          browser.select('#navList3\\:\\:content', "North Star", function (ar) {
            console.log('asdf');
          })
        } catch (e) {
            console.log(e)
        }

        resolve(tablehtml);
        //
        //
        //
        
        // Inject JQuery
        //var injectedJQuery = browser.document.createElement("script");
        //injectedJQuery.setAttribute("type","text/javascript");
        //injectedJQuery.setAttribute("src", "http://code.jquery.com/jquery-1.11.0.min.js");    
        //browser.body.appendChild(injectedJQuery);
    //
        //// Inject table2json
        //var injectedScript = browser.document.createElement("script");
        //injectedScript.setAttribute("type","text/javascript");
        //injectedScript.setAttribute("src", "http://code.jquery.com/jquery-1.11.0.min.js");    
        //browser.body.appendChild(injectedScript);

        // Wait until the scripts are loaded
        //browser.wait(function(window) {
        //  // make sure the new script tag is inserted
        //  return window.document.querySelectorAll("script").length == numscripts + 2;
        //}, function() {
        //  // scripts are ready
        //  // assert.equal(browser.evaluate("$.fn.jquery"), "1.11.0");
        //  // console.log(browser.evaluate("$('title').text()"));
        //  // console.log(browser.window.$);
        //  //
    //
        //});

        //console.log(browser.document.documentElement.innerHTML);


    });
    
  });
}


var jquery = require('fs').readFileSync(__dirname + '/vendor/jquery.min.js', 'utf-8');
var t2json = require('fs').readFileSync(__dirname + '/vendor/jquery.tabletojson.js', 'utf-8');


/**
 * Takes all that messy HTML. Returns a promise to JSON.
 * @param  {[type]} tablehtml [description]
 * @return {[type]}           [description]
 */
var convert_food_table = function (tablehtml) {
    console.log('converting')
    console.log(tablehtml)

  return new Promise(function (resolve, reject) {
    jsdom.env({ html : tablehtml,
                src : [jquery, t2json],
                done: 
        function (err, window) {
          if (err) reject(err)

          try {
            var $ = window.jQuery;
            var tbl = $('table tr').map(function() {
              return $(this).find('td').map(function() {
                if($(this).find('img').length !== 0) {
                  return 'veggie';
                }
                return $(this).text();
              }).get();
            }).get();

            if (tbl.length % 3 != 0) console.log('something is wrong with this length')

            // Now for the columns.
            
            var res = [];
            for (var i = 0; i < tbl.length; i++) {
              res.push({'where': tbl[i], 'what': tbl[++i], 'veggie': tbl[++i] === 'veggie' })
            };

            //var data = $('table').tableToJSON(); 
            resolve(res);
          } catch (e) { reject (e) }

        }
      });
  });
}



gettable().then(convert_food_table).then(console.log);

