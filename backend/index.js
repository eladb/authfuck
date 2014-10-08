var http = require('http');
var express = require('express');
var passport = require('passport');
var morgan = require('morgan');
// var cookieParser = require('cookie-parser');
// var bodyParser = require('body-parser');
// var session = require('express-session');
var BasicStrategy = require('passport-http').BasicStrategy;

var app = express();
app.use(morgan('dev'));

var FORBIDDEN = {};

passport.use(new BasicStrategy(function(username, password, done) {
  console.log('verify user', username, password);
  
  if (password === '12345') {
    return done(null, { username: username, age: 34 });
  }
  else {
    return done(FORBIDDEN);
  }
}));

// passport.serializeUser(function(user, done) {
//   console.log('serialize user', user);
//   return done(null, user.username);
// });

// passport.deserializeUser(function(id, done) {
//   console.log('deserialize user', id);
//   return done(err, { username: 'eladb', age: 34 });
// });
 
app.use(passport.initialize());

function secure() {
  return function(req, res, next) {
    var options = { session: false };
    var authfn = passport.authenticate('basic', options, function(err, user, challenge) {
      if (challenge) {
        res.status(401);
        res.setHeader('WWW-Authenticate', challenge);
        return res.end();
      }

      if (err == FORBIDDEN) {
        res.status(403);
        return res.send('forbidden');
      }

      if (err) {
        return next(err);
      }

      if (!user) {
        res.status(500);
        return res.send('error');
      }

      return req.login(user, options, function(err) {
        if (err) return next(err);
        return next();
      });
    });

    return authfn(req, res, next);
  };
}

app.get('/auth', secure(), function(req, res) {
  return res.end('OK'); // silently succeed
});

app.get('/', secure(), function(req, res) {
  res.send('hello, ' + req.user.username);
});

app.get('/foo', secure(), function(req, res) {
  console.log('foo here');
  res.send('foo ' + req.user.username);
});

var port = process.env.PORT || 5000
app.listen(port);
console.log('listening on port', port);
