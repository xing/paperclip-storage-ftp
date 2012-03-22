require "paperclip"
require "active_support/all"
require "paperclip/storage/ftp/server"

module Paperclip
  module Storage
    module Ftp
      def exists?(style = default_style)
        if original_filename
          primary_ftp_server.file_exists?(path(style))
        else
          false
        end
      end

      def primary_ftp_server
        @primary_ftp_server ||= Server.new
      end
    end
  end
end
