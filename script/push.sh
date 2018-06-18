#!/usr/bin/env bash

setup_git() {
    git config --global user.email "travis@travis-ci.org"
    git config --global user.name "Travis CI"
}

commit_website_files() {
    git branch -D master
    git checkout -b master
    mkdir temp
    mv ./* temp
    mv temp/_site/* .
    rm -rf temp
    git add .
    git commit -m "Travis build: $TRAVIS_BUILD_NUMBER"
}

upload_files() {
    git remote add origin-pages https://${GITHUB_TOKEN}@github.com/yavuzovski/yavuzovski.github.io.git
    git push --quiet --set-upstream origin-pages master --force
}

setup_git
commit_website_files
upload_files
