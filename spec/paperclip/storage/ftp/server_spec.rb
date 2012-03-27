require File.expand_path("../../../../spec_helper", __FILE__)

describe Paperclip::Storage::Ftp::Server do
  let(:server) { Paperclip::Storage::Ftp::Server.new }

  context "initialize" do
    it "accepts options to initialize attributes" do
      options = {
        :host     => "ftp.example.com",
        :user     => "user",
        :password => "password"
      }
      server = Paperclip::Storage::Ftp::Server.new(options)
      server.host.should     == "ftp.example.com"
      server.user.should     == "user"
      server.password.should == "password"
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
      server.connection.should_receive(:mkdir).with("/files")
      server.connection.should_receive(:putbinaryfile).with("/tmp/original.jpg", "/files/original.jpg")
      server.put_file("/tmp/original.jpg", "/files/original.jpg")
    end
  end

  context "#delete_file" do
    it "deletes the file on the server"
  end

  context "#connection"
end
