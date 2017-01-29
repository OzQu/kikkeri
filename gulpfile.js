var gulp = require('gulp');
var gulpLiveScript = require('gulp-livescript');
var nodemon = require('gulp-nodemon');
var sass = require('gulp-sass');
var argv = require('optimist').argv;

gulp.task('default', ['build']);

gulp.task('build', ['ls-server', 'ls-client', 'views', 'web', 'sass']);

gulp.task('ls-server', function() {
  return gulp.src('./src/*.ls')
    .pipe(gulpLiveScript({bare: true}))
    .pipe(gulp.dest('build'));
});

gulp.task('ls-client', function() {
  return gulp.src('./websrc/*.ls')
    .pipe(gulpLiveScript({bare: true}))
    .pipe(gulp.dest('build/web'));
});

gulp.task('ls-tools', function() {
  return gulp.src('./tools/datagenerator.ls')
    .pipe(gulpLiveScript({bare: true}))
    .pipe(gulp.dest('build/tools'));
});

gulp.task('web', function() {
  return gulp.src('./web/*')
    .pipe(gulp.dest('build/web'));
});
gulp.task('sass', function() {
  return gulp.src('./sass/*')
    .pipe(sass())
    .pipe(gulp.dest('build/web'));
});
gulp.task('views', function() {
  return gulp.src('./views/*.jade')
    .pipe(gulp.dest('build/views'));
});

gulp.task('generate', ['ls-tools'], function() {
  var stream = nodemon({
    script: 'build/tools/datagenerator.js',
    ext: 'js',
    env: {'NODE_ENV': 'development'},
    args: ['--games='+argv.games,
      '--scorespread='+argv.scorespread,
      '--gamesspread='+argv.gamesspread,
      '--years='+argv.years]
  });
  stream.on('exit', function() {
    process.exit();
  }).on('crash', function() {
    process.exit(1);
  })
});

gulp.task('watch', function() {
  gulp.watch('src/*.ls', ['ls-server']);
  gulp.watch('websrc/*.ls', ['ls-client']);
  gulp.watch('web/*', ['web']);
  gulp.watch('sass/*', ['sass']);
  gulp.watch('views/*.jade', ['views']);
});

gulp.task('nodemon', function() {
  nodemon({
    script: 'build/app.js',
    ext: 'js',
    env: {'NODE_ENV': 'development'},
    watch: ['build/*', 'build/views/*']
  });
});
gulp.task('dev', ['build', 'watch', 'nodemon']);

