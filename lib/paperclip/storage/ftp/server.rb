module Paperclip
  module Storage
    module Ftp
      class Server
        def file_exists?(path)
          true
        end
      end
    end
  end
end
