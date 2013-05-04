# MotionModel Sample App for SQLite3 using FMDB

= Installation

FMDB is at https://github.com/ccgus/fmdb, and must be installed in your app. See the Rakefile here for an example.
Note that the 2.0 Podspec is not up to date with some recent changes in the master branch, so for now install a
submodule locally:

`git submodule add https://github.com/aceofspades/fmdb vendor/fmdb`

Note the URL above is a fork that contains a podspec which you'll need to build locally.

For this sample app, you can install it with

`git submodule update --init`

