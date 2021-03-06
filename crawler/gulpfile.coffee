# Load all required libraries.
gulp = require 'gulp'
gutil = require 'gulp-util'
coffee = require 'gulp-coffee'
istanbul = require 'gulp-istanbul'
mocha = require 'gulp-mocha'
plumber = require 'gulp-plumber'
nodemon = require 'gulp-nodemon'

gulp.on 'err', (e) ->
  gutil.beep()
  gutil.log e.err.stack

gulp.task 'coffee', ->
  gulp.src ['./src/*.coffee', './src/*/*.coffee']
    .pipe plumber() # Pevent pipe breaking caused by errors from gulp plugins
    .pipe coffee({bare: true})
    .on('error', errorHandler)
    .pipe gulp.dest './lib/'

gulp.task 'test', ['coffee'], ->
  gulp.src ['lib/*.js']
    .pipe(istanbul()) # Covering files
    .pipe(istanbul.hookRequire()) # Overwrite require so it returns the covered files
    .on('error', errorHandler)
    .on 'finish', ->
      gulp.src(['test/*.spec.coffee'])
        .pipe mocha reporter: 'spec', compilers: 'coffee:coffee-script'
        .on('error', errorHandler)
        .pipe istanbul.writeReports() # Creating the reports after tests run

gulp.task 'watch', ->
  gulp.watch './src/*.coffee', ['coffee', 'test']
  gulp.watch './test/*.coffee', ['test']

gulp.task 'serve', () ->
  nodemon({
    script: 'server.js',
    ext: 'js coffee jade',
    stdout: false
  }).on 'readable', () ->
    this.stdout.pipe process.stdout
    this.stderr.pipe process.stderr




gulp.task 'default', ['coffee', 'serve']


# Handle the error
errorHandler = (error) ->
  console.log error.toString()
  # this.emit 'end'