require "paperclip"
require "active_support/all"
require "tempfile"

require "paperclip/storage/ftp/server"

module Paperclip
  module Storage
    module Ftp
      def exists?(style_name = default_style)
        return false unless original_filename
        with_primary_ftp_server do |server|
          server.file_exists?(path(style_name))
        end
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
          with_primary_ftp_server do |server|
            server.get_file(filename, file.path)
          end
          file.rewind
          file
        end
      end

      def flush_writes
        with_ftp_servers do |servers|
          servers.map do |server|
            Thread.new do
              @queued_for_write.each do |style_name, file|
                remote_path = path(style_name)
                log("saving ftp://#{server.user}@#{server.host}:#{remote_path}")
                server.put_file(file.path, remote_path)
              end
            end
          end.each(&:join)
        end

        after_flush_writes # allows attachment to clean up temp files

        @queued_for_write = {}
      end

      def flush_deletes
        with_ftp_servers do |servers|
          servers.map do |server|
            Thread.new do
              @queued_for_delete.each do |path|
                log("deleting ftp://#{server.user}@#{server.host}:#{path}")
                server.delete_file(path)
              end
            end
          end.each(&:join)
        end

        @queued_for_delete = []
      end

      def copy_to_local_file(style, destination_path)
        with_primary_ftp_server do |server|
          server.get_file(path(style), destination_path)
        end
      end

      def with_primary_ftp_server(&blk)
        primary_ftp_server.establish_connection
        yield primary_ftp_server
      ensure
        primary_ftp_server.close_connection
      end

      def primary_ftp_server
        ftp_servers.first
      end

      def with_ftp_servers(&blk)
        ftp_servers.each(&:establish_connection)
        yield ftp_servers
      ensure
        ftp_servers.each(&:close_connection)
      end

      def ftp_servers
        @ftp_servers ||= @options[:ftp_servers].map{|config| Server.new(config) }
      end
    end
  end
end
