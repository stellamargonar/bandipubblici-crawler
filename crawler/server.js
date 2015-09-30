var bodyParser = require('body-parser');
var express = require('express');
var app = express();
var webWrapperClass = require('./lib/webWrapper.js');
var mongoose = require('mongoose');
var config = require('./config');
process.env.NODE_ENV = 'testing';


app.use(bodyParser.urlencoded({
  extended: true
}));
app.use(bodyParser.json());
app.use(function(req, res, next) {
    res.setHeader('Access-Control-Allow-Origin', 'http://localhost:3000');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE');
    res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    next();
});

mongoose.connect('mongodb://' + config.database.host + '/' + config.database.dbName);


var server = app.listen(5000, 'localhost', function () {
  var host = server.address().address;
  var port = server.address().port;

  var webWrapper = new webWrapperClass(app);
  console.log('Example app listening at http://%s:%s', host, port);
});