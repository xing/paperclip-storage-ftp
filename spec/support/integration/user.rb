require "active_record"

class User < ActiveRecord::Base
  include Paperclip::Glue

  has_attached_file :avatar,
    :storage  => :ftp,
    :path     => ":id/:style/:filename",
    :ftp_servers => [
      {
        :host     => "127.0.0.1",
        :user     => "admin",
        :password => "admin"
      }
    ]
end

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :users
  add_attachment :users, :avatar
end
