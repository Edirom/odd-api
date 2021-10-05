var gulp = require('gulp');
var zip = require('gulp-zip');
var replace = require('gulp-replace');
var newer = require('gulp-newer');
var exist = require('@existdb/gulp-exist');
var dateformat = require('dateformat');
var fs = require('fs');

var packageJson = require('./package.json');
var existConfig = require('./existConfig.json');
var existClient = exist.createClient(existConfig);

var git = require('git-rev-sync');
var source = require('vinyl-source-stream');
var buffer = require('vinyl-buffer');
var runSequence = require('run-sequence').use(gulp);

//handles xqueries
gulp.task('xql', function(){
    return gulp.src('source/xql/**/*')
        .pipe(newer('build/resources/xql/'))
        .pipe(gulp.dest('build/resources/xql/'));
});

//deploys xql to exist-db
gulp.task('deploy-xql', gulp.series('xql', function (done) {
    gulp.src(['**/*'], {cwd: 'build/resources/xql/'})
        .pipe(existClient.newer({target: '/db/apps/odd-api/resources/xql/'}))
        .pipe(existClient.dest({target: '/db/apps/odd-api/resources/xql/'}));
        
    done();
}));

gulp.task('controller', function(){
    return gulp.src('source/exist-db/controller.xql')
        .pipe(newer('build/'))
        .pipe(gulp.dest('build/'));
});

//deploys controller.xql to exist-db
gulp.task('deploy-controller',gulp.series('controller', function(done) {
    gulp.src(['controller.xql'], {cwd: 'build/'})
        .pipe(existClient.newer({target: "/db/apps/odd-api/"}))
        .pipe(existClient.dest({target: '/db/apps/odd-api/'}));
        
    done();
}));

//handles html
gulp.task('html', function(){
    
    //var git = getGitInfo();
    
    return gulp.src('./source/html/**/*')
        //.pipe(newer('./build/'))
        //.pipe(replace('$$git-url$$', git.url))
        //.pipe(replace('$$git-short$$', git.short))
        //.pipe(replace('$$git-dirty$$', git.dirty))
        .pipe(gulp.dest('./build/'));
});

//deploys html to exist-db
gulp.task('deploy-html', gulp.series('html', function(done) {
    gulp.src('**/*.html', {cwd: './build/'})
        .pipe(existClient.newer({target: "/db/apps/odd-api/"}))
        .pipe(existClient.dest({target: '/db/apps/odd-api/'}));

done();
}));

//handles data
gulp.task('data', function(){
    return gulp.src('./data/**/*')
        .pipe(newer('./build/data/'))
        .pipe(gulp.dest('./build/data/'));
});

//deploys data to exist-db
gulp.task('deploy-data', gulp.series('data', function(done) {
    gulp.src('**/*', {cwd: 'build/data/'})
        .pipe(existClient.newer({target: "/db/apps/odd-api/data/"}))
        .pipe(existClient.dest({target: '/db/apps/odd-api/data/'}));
done();
}));

//set up basic xar structure
gulp.task('xar-structure', function() {
    return gulp.src(['./source/eXist-db/**/*'])
        .pipe(replace('$$deployed$$', dateformat(Date.now(), 'isoUtcDateTime')))
        .pipe(replace('$$version$$', getPackageJsonVersion()))
        .pipe(replace('$$desc$$', packageJson.description))
        .pipe(replace('$$license$$', packageJson.license))
        .pipe(replace('$$name$$', packageJson.name))
        .pipe(gulp.dest('./build/'));
    
});

//empty build folder
gulp.task('del', function() {
    return del(['./build/**/*','./dist/' + packageJson.name + '-' + getPackageJsonVersion() + '.xar']);
});

//reading from fs as this prevents caching problems    
function getPackageJsonVersion() {
    return JSON.parse(fs.readFileSync('./package.json', 'utf8')).version;
}
 
/**
 * deploys the current build folder into a (local) exist database
 */
/*gulp.task('deploy', gulp.series('deploy-data', 'deploy-html', 'deploy-xql', 'deploy-controller', function (done) {
    done();
}));*/

gulp.task('dist-finish', function() {
    return gulp.src('./build/**/*')
        .pipe(zip(packageJson.name + '-' + getPackageJsonVersion() + '.xar'))
        .pipe(gulp.dest('./dist'));
})

//creates a dist version
gulp.task('dist', gulp.series('xar-structure', 'html', 'xql', 'data', 'dist-finish', function (done) {
    done();
}));

//reading from fs as this prevents caching problems    
function getPackageJsonVersion() {
    return JSON.parse(fs.readFileSync('./package.json', 'utf8')).version;
}

function getGitInfo() {
    return {short: git.short(),
            url: 'https://github.com/Edirom/odd-api/commit/' + git.short(),
            dirty: git.isDirty()}
}

gulp.task('git-info',function() {
    console.log('Git Information: ')
    console.log(git.short());
    console.log(git.remoteUrl());
    console.log(git.isDirty());
    console.log('link is https://github.com/Edirom/odd-api/commit/' + git.short());
});

gulp.task('default', function() {
    console.log('')
    console.log('INFO: There is no default task, please run one of the following tasks:');
    console.log('');
    console.log('  "gulp dist"       : creates a xar from the current sources');
    console.log();
});