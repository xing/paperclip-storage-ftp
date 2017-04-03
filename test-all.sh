#!/bin/bash
#
# Run specs against all supported ruby and paperclip versions
# using RVM (http://rvm.io/)

set -e

# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
  # First try to load from a user install
  source "$HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  # Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"
else
  printf "ERROR: An RVM installation was not found.\n"
fi

for ruby in '2.2' '2.3' '2.4'
do
  rvm use $ruby --fuzzy
  gem install bundler --conservative --no-rdoc --no-ri

  for gemfile in gemfiles/Gemfile.paperclip-*.x
  do
    bundle install --gemfile=$gemfile
    BUNDLE_GEMFILE=$gemfile bundle exec rake
  done
done
