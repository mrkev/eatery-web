'use strict';
var dining = require("Iroh");

console.log(dining.query().then(console.log));

console.log(dining.query('okenshields').then(console.log));
