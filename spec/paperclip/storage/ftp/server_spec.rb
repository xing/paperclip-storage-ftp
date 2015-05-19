require "spec_helper"

describe Paperclip::Storage::Ftp::Server do
  let(:server) { Paperclip::Storage::Ftp::Server.new }

  context "initialize" do
    it "accepts options to initialize attributes" do
      options = {
        :host            => "ftp.example.com",
        :user            => "user",
        :password        => "password",
        :port            => 2121,
        :passive         => true,
        :connect_timeout => 2
      }
      server = Paperclip::Storage::Ftp::Server.new(options)
      options.each{|k,v| server.send(k).should == v }
    end

    it "sets a default port" do
      server = Paperclip::Storage::Ftp::Server.new
      server.port.should == Net::FTP::FTP_PORT
    end
  end

  context "#file_exists?" do
    before do
      server.stub(:connection).and_return(double("connection"))
    end

    it "returns true if the file exists on the server" do
      server.connection.should_receive(:nlst).with("/files/original").and_return(["foo.jpg"])
      server.file_exists?("/files/original/foo.jpg").should be true
    end

    it "recognizes complete file paths correctly" do
      server.connection.should_receive(:nlst).with("/files/original").and_return(["/files/original/foo.jpg"])
      server.file_exists?("/files/original/foo.jpg").should be true
    end

    it "returns false if the file does not exist on the server" do
      server.connection.should_receive(:nlst).with("/files/original").and_return([])
      server.file_exists?("/files/original/foo.jpg").should be false
    end

    it "returns false if the ftp server responds with a FTPTempError" do
      server.connection.should_receive(:nlst).with("/files/original").and_raise(Net::FTPTempError)
      server.file_exists?("/files/original/foo.jpg").should be false
    end

    it "returns false if the ftp server responds with a FTPPermError" do
      server.connection.should_receive(:nlst).with("/files/original").and_raise(Net::FTPPermError)
      server.file_exists?("/files/original/foo.jpg").should be false
    end
  end

  context "#get_file" do
    before do
      server.stub(:connection).and_return(double("connection"))
    end

    it "returns the file object" do
      server.connection.should_receive(:getbinaryfile).with("/files/original.jpg", "/tmp/original.jpg")
      server.get_file("/files/original.jpg", "/tmp/original.jpg")
    end
  end

  context "#put_file" do
    before do
      server.stub(:connection).and_return(double("connection"))
    end

    it "stores the file on the server" do
      server.should_receive(:mkdir_p).with("/files")
      server.connection.should_receive(:putbinaryfile).with("/tmp/original.jpg", "/files/original.jpg")
      server.put_file("/tmp/original.jpg", "/files/original.jpg")
    end
  end

  context "#delete_file" do
    before do
      server.stub(:connection).and_return(double("connection"))
    end

    it "deletes the file on the server" do
      server.connection.should_receive(:delete).with("/files/original.jpg")
      server.delete_file("/files/original.jpg")
    end
  end

  context "#rmdir_p" do
    before do
      server.stub(:connection).and_return(double("connection"))
    end

    it "deletes the directory and all parent directories" do
      server.connection.should_receive(:rmdir).with("/files/foo/bar")
      server.connection.should_receive(:rmdir).with("/files/foo")
      server.connection.should_receive(:rmdir).with("/files"){ raise Net::FTPPermError }
      server.connection.should_not_receive(:rmdir).with("/")
      server.rmdir_p("/files/foo/bar")
    end
  end

  context "#establish_connection" do
    it "creates the ftp connection for the given server" do
      ftp = double("ftp")
      Net::FTP.should_receive(:new).and_return(ftp)
      ftp.should_receive(:passive=).with(server.passive)
      ftp.should_receive(:connect).with(server.host, server.port)
      ftp.should_receive(:login).with(server.user, server.password)
      server.establish_connection
      server.connection.should == ftp
    end
  end

  context "mkdir_p" do
    before do
      server.stub(:connection).and_return(double("connection"))
    end

    it "creates the directory and all its parent directories" do
      server.connection.should_receive(:mkdir).with("/").ordered
      server.connection.should_receive(:mkdir).with("/files").ordered
      server.connection.should_receive(:mkdir).with("/files/foo").ordered
      server.connection.should_receive(:mkdir).with("/files/foo/bar").ordered
      server.mkdir_p("/files/foo/bar")
    end

    it "does not stop on Net::FTPPermError" do
      server.connection.should_receive(:mkdir).with("/").and_raise(Net::FTPPermError)
      server.connection.should_receive(:mkdir).with("/files")
      server.mkdir_p("/files")
    end
  end
end
