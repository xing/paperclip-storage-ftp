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

        def get_file(path, tempfile_path)
          connection.getbinaryfile(path, tempfile_path)
        end
      end
    end
  end
end
