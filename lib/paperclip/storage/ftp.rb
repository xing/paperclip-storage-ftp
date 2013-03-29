require "paperclip"
require "active_support/all"
require "tempfile"

require "paperclip/storage/ftp/server"

module Paperclip
  module Storage
    module Ftp
      def exists?(style_name = default_style)
        original_filename && primary_ftp_server.file_exists?(path(style_name))
      end

      def to_file(style_name = default_style)
        if file = @queued_for_write[style_name]
          file.rewind
          file
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

      def flush_writes
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
        @ftp_servers ||= @options[:ftp_servers].map{|config| Server.new(config) }
      end

      def primary_ftp_server
        ftp_servers.first
      end
    end
  end
end
