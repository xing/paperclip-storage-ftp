require "pathname"

module Paperclip
  module Storage
    module Ftp
      class Server
        attr_accessor :host, :user, :password
        attr_accessor :connection

        def initialize(options = {})
          options.each do |k,v|
            send("#{k}=", v)
          end
        end

        def file_exists?(path)
          pathname = Pathname.new(path)
          connection.nlst(pathname.dirname.to_s).include?(pathname.basename.to_s)
        end

        def get_file(remote_file_path, local_file_path)
          connection.getbinaryfile(remote_file_path, local_file_path)
        end

        def put_file(local_file_path, remote_file_path)
          pathname = Pathname.new(remote_file_path)
          connection.mkdir(pathname.dirname.to_s)
          connection.putbinaryfile(local_file_path, remote_file_path)
        end
      end
    end
  end
end
