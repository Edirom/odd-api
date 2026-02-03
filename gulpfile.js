import gulp from 'gulp';
import zip from 'gulp-zip';
import replace from 'gulp-replace';
import newer from 'gulp-newer';
import exist from '@existdb/gulp-exist';
import dateformat from 'dateformat';
import fs from 'fs';
import { readFileSync } from 'fs';
import git from 'git-rev-sync';
import { deleteAsync } from 'del';
import { exec } from 'child_process';

const packageJson = JSON.parse(readFileSync('./package.json', 'utf8'));
const existConfig = JSON.parse(readFileSync('./existConfig.json', 'utf8'));
const existClient = exist.createClient(existConfig);


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

// simply copies the openapi v1 file to the build folder
gulp.task('openapi_v1', function(){
    return gulp.src('./source/openapi/v1/openapi_v1.yaml')
        .pipe(gulp.dest('./build/'));
});

// bundles the v2 openapi file using redocly and saves it to the build folder
gulp.task('openapi_v2', function (done) {

    // create the target folder
    const outputDir = './build';
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    // run redocly to bundle the OpenAPI description
    exec('npx @redocly/cli bundle source/openapi/v2/openapi_v2.yaml -o build/openapi_v2.yaml', (err, stdout, stderr) => {
        if (err) {
            console.error('Failed to bundle the OpenAPI description: ', stderr);
            done(err);
            return;
        }
        done();
    });
});

//empty build folder
gulp.task('del', function() {
    return deleteAsync(['./build/**/*','./dist/' + packageJson.name + '-' + getPackageJsonVersion() + '.xar']);
});

/**
 * deploys the current build folder into a (local) exist database
 */
/*gulp.task('deploy', gulp.series('deploy-data', 'deploy-html', 'deploy-xql', function (done) {
    done();
}));*/

gulp.task('dist-finish', function() {
    return gulp.src('./build/**/*')
        .pipe(zip(packageJson.name + '-' + getPackageJsonVersion() + '.xar'))
        .pipe(gulp.dest('./dist'));
})

//creates a dist version
gulp.task('dist', gulp.series('xar-structure', 'html', 'xql', 'data', 'openapi_v1', 'openapi_v2', 'dist-finish', function (done) {
    done();
}));

//copies XQSuite test files to the build folder
gulp.task('xqsuite', function(){
    return gulp.src('./tests/xqsuite/**/*')
        .pipe(gulp.dest('./build/xqsuite'));
});

//creates a dist version including the XQSuite tests
gulp.task('dist-with-tests', gulp.series('xqsuite', 'dist', function (done) {
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

gulp.task('git-info', function() {
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
