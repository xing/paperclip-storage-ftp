require "pathname"

module Paperclip
  module Storage
    module Ftp
      class Server
        attr_accessor :connection

        def file_exists?(path)
          pathname = Pathname.new(path)
          connection.nlst(pathname.dirname.to_s).include?(pathname.basename.to_s)
        end

        # def get_file(path)
        #   File.new(path(style_name), 'rb')
        # end
      end
    end
  end
end
