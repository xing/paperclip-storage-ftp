require "pathname"
require "net/ftp"

module Paperclip
  module Storage
    module Ftp
      class Server

        attr_accessor :host, :user, :password, :port, :passive
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
          @connection.connect(host, port)
          @connection.login(user, password)
        end

        def close_connection
          connection.close if connection && !connection.closed?
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
      end
    end
  end
end
