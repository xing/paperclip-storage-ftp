require "pathname"
require "net/ftp"
require "timeout"

module Paperclip
  module Storage
    module Ftp
      class Server

        attr_accessor :host, :user, :password, :port, :passive,
                      :connect_timeout, :ignore_connect_errors

        attr_reader   :connection

        def initialize(options = {})
          options.each do |k,v|
            send("#{k}=", v)
          end

          @port ||= Net::FTP::FTP_PORT
        end

        def establish_connection
          @connection = Net::FTP.new
          @connection.passive = passive

          if ignore_connect_errors
            begin
              connect
            rescue SystemCallError => e
              Paperclip.log("could not connect to ftp://#{user}@#{host}:#{port} (#{e})")
              @connection = nil
              return
            end
          else
            connect
          end

          @connection.login(user, password)
        end

        def close_connection
          connection.close if connected?
        end

        def connected?
          connection && !connection.closed?
        end

        def file_exists?(path)
          pathname = Pathname.new(path)
          connection.nlst(pathname.dirname.to_s).map{|f| File.basename f }.include?(pathname.basename.to_s)
        rescue Net::FTPTempError
          false
        end

        def get_file(remote_file_path, local_file_path)
          connection.getbinaryfile(remote_file_path, local_file_path)
        end

        def put_file(local_file_path, remote_file_path)
          pathname = Pathname.new(remote_file_path)
          mkdir_p(pathname.dirname.to_s)
          connection.putbinaryfile(local_file_path, remote_file_path)
        end

        def delete_file(remote_file_path)
          connection.delete(remote_file_path)
        end

        def rmdir_p(dir_path)
          while(true)
            connection.rmdir(dir_path)
            dir_path =  File.dirname(dir_path)
          end
        rescue Net::FTPTempError, Net::FTPPermError
          # Stop trying to remove parent directories
        end

        def mkdir_p(dirname)
          pathname = Pathname.new(dirname)
          pathname.descend do |p|
            begin
              connection.mkdir(p.to_s)
            rescue Net::FTPPermError
              # This error can be caused by an existing directory.
              # Ignore, and keep on trying to create child directories.
            end
          end
        end

        private

        def connect
          if connect_timeout
            Timeout.timeout(connect_timeout, Errno::ETIMEDOUT) do
              @connection.connect(host, port)
            end
          else
            @connection.connect(host, port)
          end
        end
      end
    end
  end
end
