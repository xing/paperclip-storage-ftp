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
        rescue Net::FTPTempError, Net::FTPPermError
          false
        end

        def get_file(remote_file_path, local_file_path)
          connection.getbinaryfile(remote_file_path, local_file_path)
        end

        def put_file(local_file_path, remote_file_path, check_existence = true)
          pathname = Pathname.new(remote_file_path)
          directory = pathname.dirname.to_s
          mkdir_p(directory) if check_existence && !file_exists?(directory)
          connection.putbinaryfile(local_file_path, remote_file_path)
        end

        def put_files(file_paths)
          if file_paths.length > 1
            tree = directory_tree(file_paths.values)
            mktree(tree)
            file_paths.each do |local_file_path, remote_file_path|
              put_file(local_file_path, remote_file_path, false)
            end
          elsif file_paths.length == 1
            put_file(file_paths.first.first, file_paths.first.last)
          end
        end

        def directory_tree(file_paths)
          directories = file_paths.map do |path|
            Pathname.new(path).dirname.to_s.split("/").reject(&:empty?)
          end
          tree = Hash.new {|h, k| h[k] = Hash.new(&h.default_proc)}
          directories.each do |directory|
            directory.inject(tree){|h,k| h[k]}
          end
          tree
        end

        def delete_file(remote_file_path)
          connection.delete(remote_file_path)
        end

        def rmdir_p(dir_path)
          while(true)
            connection.rmdir(dir_path)
            dir_path = File.dirname(dir_path)
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

        def mktree(tree, base = "/")
          return unless tree.any?
          list = connection.nlst(base)
          tree.reject{|k,_| list.include?(k)}.each do |directory, sub_directories|
            begin
              connection.mkdir(base + directory)
            rescue Net::FTPPermError
              # This error can be caused by an already existing directory,
              # maybe it was created in the meantime.
            end
          end
          tree.each do |directory, sub_directories|
            mktree(sub_directories, base + directory + "/")
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
