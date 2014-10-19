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

        // Count script objects
        var numscripts = browser.document.querySelectorAll("script").length
        var tablehtml = browser.document.querySelector("#t2\\:\\:db").innerHTML; // Escape those got damn colons. Damn I hate Oracle.

        try {
          browser.select('#navList3\\:\\:content', "North Star", function (ar) {
            console.log('asdf');
          })
        } catch (e) {
            console.log(e)
        }

        resolve(tablehtml);
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