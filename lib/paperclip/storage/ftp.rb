require "paperclip"
require "active_support/all"
require "paperclip/storage/ftp/server"

module Paperclip
  module Storage
    module Ftp
      def exists?(style_name = default_style)
        if original_filename
          primary_ftp_server.file_exists?(path(style_name))
        else
          false
        end
      end

      def to_file(style_name = default_style)
        if @queued_for_write[style_name]
          @queued_for_write[style_name].rewind
          @queued_for_write[style_name]
        else
          primary_ftp_server.get_file(path(style_name))
        end
      end

      def ftp_servers
        @ftp_servers ||= begin
          ftp_servers = []
          @options[:ftp_servers].each do |config|
            server = Server.new(
              :host     => config[:host],
              :user     => config[:user],
              :password => config[:password]
            )
            ftp_servers << server
          end
          ftp_servers
        end
      end

      def primary_ftp_server
        ftp_servers.first
      end
    end
  end
end
