require "paperclip"
require "tempfile"

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
          filename = path(style_name)
          extname  = File.extname(filename)
          basename = File.basename(filename, extname)
          file     = Tempfile.new([basename, extname])
          primary_ftp_server.get_file(filename, file.path)
          file.rewind
          file
        end
      end

      def flush_writes #:nodoc:
        @queued_for_write.each do |style_name, file|
          file.close
          ftp_servers.each do |server|
            remote_path = path(style_name)
            log("saving ftp://#{server.user}@#{server.host}:#{remote_path}")
            server.put_file(file.path, remote_path)
          end
        end

        after_flush_writes # allows attachment to clean up temp files

        @queued_for_write = {}
      end

      def flush_deletes
        @queued_for_delete.each do |path|
          ftp_servers.each do |server|
            log("deleting ftp://#{server.user}@#{server.host}:#{path}")
            server.delete_file(path)
          end
        end
        @queued_for_delete = []
      end

      def copy_to_local_file(style, destination_path)
        primary_ftp_server.get_file(path(style), destination_path)
      end

      def ftp_servers
        @ftp_servers ||= begin
          ftp_servers = []
          @options[:ftp_servers].each do |config|
            server = Server.new(
              :host     => config[:host],
              :user     => config[:user],
              :password => config[:password],
              :port     => config[:port]
            )
            ftp_servers << server
          end
          ftp_servers
        end
      end

      def primary_ftp_server
        ftp_servers[0]
      end
    end
  end
end
