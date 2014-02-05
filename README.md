# FTP Storage for Paperclip

Allow [Paperclip](https://github.com/thoughtbot/paperclip) attachments
to be stored on FTP servers.

## Build status

[![Build Status](https://secure.travis-ci.org/xing/paperclip-storage-ftp.png)](http://travis-ci.org/xing/paperclip-storage-ftp)

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem "paperclip-storage-ftp"
```

And then execute:

    $ bundle

Or install it manually:

    $ gem install paperclip-storage-ftp

## Usage

Somewhere in your code:

```ruby
require "paperclip/storage/ftp"
```

In your model:

```ruby
class User < ActiveRecord::Base
  has_attached_file :avatar,

    # Choose the FTP storage backend
    :storage => :ftp,

    # Set where to store the file on the FTP server(s).
    # This supports Paperclip::Interpolations.
    :path => "/path_on_ftp_server/:attachment/:id/:style/:filename",

    # The full URL of where the attachment is publicly accessible.
    # This supports Paperclip::Interpolations.
    :url => "/url_prefix/:attachment/:id/:style/:filename",

    # The list of FTP servers to use
    :ftp_servers => [
      {
        :host     => "ftp1.example.com",
        :user     => "foo",
        :password => "bar"
      },
      # Add more servers if needed
      {
        :host     => "ftp2.example.com",
        :user     => "foo",
        :password => "bar",
        :port     => 2121, # optional, 21 by default
        :passive  => true  # optional, false by default
      }
    ],

    # Optional socket connect timeout (in seconds).
    # This only limits the connection phase, once connected this option is of no more use.
    :ftp_connect_timeout => 5, # optional, nil by default (OS default timeout)

    # If set to true and the connection to a particular server cannot be established,
    # the connection error will be ignored and the files will not be uploaded to that server.
    # If set to false and the connection to a particular server cannot be established,
    # a SystemCallError will be raised (Errno::ETIMEDOUT, Errno::ENETUNREACH, etc.).
    :ftp_ignore_failing_connections => true # optional, false by default
end
```

## Changelog

### 1.2.0

* New options `:ftp_connect_timeout` and `:ftp_ignore_failing_connections`. See usage example above.

### 1.1.0

Mostly performance enhancements

* Use one thread per server to upload assets to multiple servers in parallel [#10](https://github.com/xing/paperclip-storage-ftp/issues/10)
* Avoid excessive reconnects to reduce overall upload time
* Close connnection immediately after being used

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

Copyright (c) 2014 [XING AG](http://www.xing.com)

Released under the MIT license. For full details see [LICENSE](https://github.com/xing/paperclip-storage-ftp/blob/master/LICENSE)
included in this distribution.
