#!/bin/bash
#
# Run specs against all supported ruby and paperclip versions
# using RVM (http://rvm.io/)

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

for ruby in '1.9.3' '2.0.0' '2.1.0' 'jruby --1.9' 'rbx'
do
  rvm try_install $ruby
  rvm use $ruby
  gem install bundler --conservative --no-rdoc --no-ri

  for paperclip_version in 2 3 4
  do
    gemfile="gemfiles/Gemfile.paperclip-${paperclip_version}.x"
    bundle install --gemfile=$gemfile
    BUNDLE_GEMFILE=$gemfile bundle exec rake
  done
done
