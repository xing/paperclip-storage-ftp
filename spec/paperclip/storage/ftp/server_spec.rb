require "spec_helper"

describe Paperclip::Storage::Ftp::Server do
  let(:server) { Paperclip::Storage::Ftp::Server.new }

  context "initialize" do
    it "accepts options to initialize attributes" do
      options = {
        :host     => "ftp.example.com",
        :user     => "user",
        :password => "password",
        :port     => 2121
      }
      server = Paperclip::Storage::Ftp::Server.new(options)
      server.host.should     == options[:host]
      server.user.should     == options[:user]
      server.password.should == options[:password]
      server.port.should     == options[:port]
    end

    it "sets a default port" do
      server = Paperclip::Storage::Ftp::Server.new
      server.port.should == Net::FTP::FTP_PORT
    end
  end

  context "#file_exists?" do
    it "returns true if the file exists on the server" do
      server.connection = double("connection")
      server.connection.should_receive(:nlst).with("/files/original").and_return(["foo.jpg"])
      server.file_exists?("/files/original/foo.jpg").should be_true
    end

    it "returns false if the file does not exist on the server" do
      server.connection = double("connection")
      server.connection.should_receive(:nlst).with("/files/original").and_return([])
      server.file_exists?("/files/original/foo.jpg").should be_false
    end
  end

  context "#get_file" do
    it "returns the file object" do
      server.connection = double("connection")
      server.connection.should_receive(:getbinaryfile).with("/files/original.jpg", "/tmp/original.jpg")
      server.get_file("/files/original.jpg", "/tmp/original.jpg")
    end
  end

  context "#put_file" do
    it "stores the file on the server" do
      server.connection = double("connection")
      server.should_receive(:mkdir_p).with("/files")
      server.connection.should_receive(:putbinaryfile).with("/tmp/original.jpg", "/files/original.jpg")
      server.put_file("/tmp/original.jpg", "/files/original.jpg")
    end
  end

  context "#delete_file" do
    it "deletes the file on the server" do
      server.connection = double("connection")
      server.connection.should_receive(:delete).with("/files/original.jpg")
      server.delete_file("/files/original.jpg")
    end
  end

  context "#connection" do
    it "returns a memoized ftp connection to the given server" do
      server.host     = "ftp.example.com"
      server.user     = "user"
      server.password = "password"

      connection = double("connection")
      Net::FTP.should_receive(:new).once.and_return(connection)
      connection.should_receive(:connect).once.with(server.host, server.port)
      connection.should_receive(:login).once.with(server.user, server.password)

      2.times { server.connection.should == connection }
    end
  end

  context "mkdir_p" do
    it "creates the directory and all its parent directories" do
      server.connection = double("connection")
      server.connection.should_receive(:mkdir).with("/").ordered
      server.connection.should_receive(:mkdir).with("/files").ordered
      server.connection.should_receive(:mkdir).with("/files/foo").ordered
      server.connection.should_receive(:mkdir).with("/files/foo/bar").ordered
      server.mkdir_p("/files/foo/bar")
    end

    it "does not stop on Net::FTPPermError" do
      server.connection = double("connection")
      server.connection.should_receive(:mkdir).with("/").and_raise(Net::FTPPermError)
      server.connection.should_receive(:mkdir).with("/files")
      server.mkdir_p("/files")
    end
  end
end
