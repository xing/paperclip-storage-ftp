# FTP Storage for Paperclip

Allow [Paperclip](https://github.com/thoughtbot/paperclip) attachments
to be stored on FTP servers.

## Build status

[![Build Status](https://secure.travis-ci.org/xing/paperclip-storage-ftp.png)](http://travis-ci.org/xing/paperclip-storage-ftp)

## Installation

Add this line to your application's Gemfile:

    gem 'paperclip-storage-ftp'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paperclip-storage-ftp

## Usage

Somewhere in your code:

    require "paperclip/storage/ftp"

In your model:

    class User < ActiveRecord::Base
      has_attached_file :avatar,

        # Choose the FTP storage backend
        :storage => :ftp,

        # Set where to store the file on the FTP server(s).
        # This supports Paperclip::Interpolations.
        :path => "/path_on_ftp_server/:attachment/:id/:style/:filename"

        # The full URL of where the attachment is publicly accessible.
        # This supports Paperclip::Interpolations.
        :url => "/url_prefix/:attachment/:id/:style/:filename"

        # The list of FTP servers to use
        :ftp_servers => [
          {
            :host     => "ftp1.example.com",
            :user     => "foo",
            :password => "bar",
            :port     => 21 # optional
          },
          # Add more servers if needed
          {
            :host     => "ftp2.example.com",
            :user     => "foo",
            :password => "bar",
            :port     => 2121
          }
        ]
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Authors

* [Sebastian Röbke](https://github.com/boosty)
* and other friendly [contributors](https://github.com/xing/paperclip-storage-ftp/graphs/contributors)

You can find out more about our work on our [dev blog](http://devblog.xing.com).

Copyright (c) 2012 [XING AG](http://www.xing.com)

Released under the MIT license. For full details see [LICENSE](https://github.com/xing/paperclip-storage-ftp/blob/master/LICENSE)
included in this distribution.
