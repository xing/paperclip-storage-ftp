require "active_record"

ActiveRecord::Base.raise_in_transactional_callbacks = true

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

  def self.setup_avatar_attachment(options = avatar_options)
    has_attached_file :avatar, options
    validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/
  end
end

class User < UserBase
  setup_avatar_attachment
end

class UserWithConnectTimeout < UserBase
  TIMEOUT = 0.1

  setup_avatar_attachment(avatar_options.merge(
    :ftp_servers => [
      {
        :host => "127.0.0.2" # should raise Errno::ETIMEDOUT
      }
    ],
    :ftp_connect_timeout => TIMEOUT
  ))
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
  setup_avatar_attachment(avatar_options.merge(
    :ftp_ignore_failing_connections => true
  ))
end

class UserNotIgnoringFailingConnection < UserWithInvalidPort
  setup_avatar_attachment(avatar_options.merge(
    :ftp_ignore_failing_connections => false
  ))
end

class UserDisablingEmptyDirectoryRemoval < User
  setup_avatar_attachment(avatar_options.merge(
    :ftp_keep_empty_directories => true
  ))
end
