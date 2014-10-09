require "paperclip"
require "active_support/all"
require "tempfile"

require "paperclip/storage/ftp/server"

module Paperclip
  module Storage
    module Ftp

      class NoServerAvailable < StandardError; end

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

                log("deleting empty parent directories ftp://#{server.user}@#{server.host}:#{path}")
                server.rmdir_p(File.dirname(path))
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
        server = primary_ftp_server
        begin
          yield server
        ensure
          server.close_connection
        end
      end

      def primary_ftp_server
        @options[:ftp_servers].each do |server_options|
          server = build_and_connect_server(server_options)
          return server if server.connected?
        end
        raise NoServerAvailable
      end

      def with_ftp_servers(&blk)
        servers = ftp_servers
        begin
          yield servers
        ensure
          servers.each(&:close_connection)
        end
      end

      def ftp_servers
        servers = @options[:ftp_servers].map do |server_options|
          build_and_connect_server(server_options)
        end
        available_servers = servers.select{|s| s.connected? }
        raise NoServerAvailable if available_servers.empty?
        available_servers
      end

      def build_and_connect_server(server_options)
        server = Server.new(server_options.merge(
          :connect_timeout       => @options[:ftp_connect_timeout],
          :ignore_connect_errors => @options[:ftp_ignore_failing_connections]
        ))
        server.establish_connection
        server
      end
    end
  end
end
