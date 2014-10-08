'use strict';
var Promise = require('es6-promise').Promise;
var phridge = require('phridge');
var path = require("path");

phridge.spawn({
        loadImages: false
    }).then(function(phantom) {
        var page = phantom.createPage();

        var jquery = path.resolve(__dirname, "./jquery.js");

        console.log(jquery);

        return page.run(jquery, function(jquery, resolve, reject) {
            var page = this;

            // onInitialized is called after the web page is created but before
            // a URL is loaded according to the docs of PhantomJS
            // @see http://phantomjs.org/api/webpage/handler/on-initialized.html
            page.onInitialized = function() {
                page.injectJs(jquery);
            };

            console.log(jquery)


            page.open("http://en.wikipedia.org/wiki/The_Book_of_Mozilla", function(status) {
                var hasJQuery;
                var title;

                if (status !== "success") {
                    reject(new Error("Cannot load: Phantomjs returned status " + status));
                    return;
                } else {
                    console.log(status)
                }

                // check if AudioContext is available on the window-object
                hasJQuery = page.evaluate(function() {
                    return Boolean(window.jQuery);
                });

                var title = page.evaluate(function () {
                    return $('#firstHeading').text()
                })


                if (!hasJQuery) {
                    reject(new Error("Something went wrong while injecting the JQuery"));
                    return;
                }
                resolve(title);
            });
        });
    })
    .finally(phridge.disposeAll)

.done(function(text) {
    console.log("Headline: '%s'", text);
}, function(err) {
    // Don't forget to handle errors
    // In this case we're just throwing it
    throw err;
});;