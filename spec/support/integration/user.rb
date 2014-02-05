require "active_record"

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :users
  add_column :users, :avatar_file_name, :string
  add_column :users, :avatar_content_type, :string
  add_column :users, :avatar_file_size, :integer
  add_column :users, :avatar_updated_at, :datetime
end

class UserBase < ActiveRecord::Base
  include Paperclip::Glue
  self.table_name = "users"

  def self.avatar_options
    {
      :storage  => :ftp,
      :styles   => { :medium => "50x50>", :thumb => "10x10>" },
      :path     => "/:style/:filename",
      :ftp_servers => [
        {
          :host     => "127.0.0.1",
          :user     => "user1",
          :password => "secret1",
          :port     => 2121
        },
        {
          :host     => "127.0.0.1",
          :user     => "user2",
          :password => "secret2",
          :port     => 2121
        }
      ]
    }
  end

  # must be called after has_attached_file
  def self.setup_validation
    validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/
  end
end

class User < UserBase
  has_attached_file :avatar, avatar_options
  setup_validation
end

class UserWithConnectTimeout < UserBase
  TIMEOUT = 0.1

  has_attached_file :avatar, avatar_options.merge(
    :ftp_servers => [
      {
        :host => "127.0.0.2" # should raise Errno::ETIMEDOUT
      }
    ],
    :ftp_connect_timeout => TIMEOUT
  )
  setup_validation
end

class UserWithInvalidPort < UserBase
  def self.avatar_options
    super.merge(
      :ftp_servers => [
        {
          :host     => "127.0.0.1",
          :user     => "user1",
          :password => "secret1",
          :port     => 2121
        },
        {
          :host     => "127.0.0.1",
          :user     => "user2",
          :password => "secret2",
          :port     => 2122 # should raise Errno::ECONNREFUSED
        }
      ]
    )
  end
end

class UserIgnoringFailingConnection < UserWithInvalidPort
  has_attached_file :avatar, avatar_options.merge(
    :ftp_ignore_failing_connections => true
  )
  setup_validation
end

class UserNotIgnoringFailingConnection < UserWithInvalidPort
  has_attached_file :avatar, avatar_options.merge(
    :ftp_ignore_failing_connections => false
  )
  setup_validation
end
