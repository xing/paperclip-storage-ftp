require "spec_helper"

describe Paperclip::Storage::Ftp::Server do
  let(:server) { Paperclip::Storage::Ftp::Server.new }
  let(:connection) { double("connection") }

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
      server.stub(:connection).and_return(connection)
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
      server.stub(:connection).and_return(connection)
    end

    it "returns the file object" do
      server.connection.should_receive(:getbinaryfile).with("/files/original.jpg", "/tmp/original.jpg")
      server.get_file("/files/original.jpg", "/tmp/original.jpg")
    end
  end

  context "#put_file" do
    before do
      server.stub(:connection).and_return(connection)
    end

    it "stores the file on the server" do
      server.connection.should_receive(:putbinaryfile).with("/tmp/original.jpg", "/files/original.jpg")
      server.put_file("/tmp/original.jpg", "/files/original.jpg")
    end
  end

  context "#put_files" do
    before do
      server.stub(:connection).and_return(connection)
    end

    shared_examples "proper handling" do
      it "passes files to #put_file" do
        server.should_receive(:mktree).with(tree)
        server.should_receive(:put_file).with(files.keys.first, files.values.first).ordered
        server.should_receive(:put_file).with(files.keys.last, files.values.last).ordered
        server.put_files files
      end
    end

    context "common directories" do
      let(:files) do
        {
          "/tmp/foo1.jpg" => "/bar/foo1.jpg",
          "/tmp/foo2.jpg" => "/bar/foo2.jpg"
        }
      end
      let(:tree) { { "bar"=>{} } }

      include_examples "proper handling"
    end

    context "no common directories" do
      let(:files) do
        {
          "/tmp/foo1.jpg" => "/bar/foo1.jpg",
          "/tmp/foo2.jpg" => "/baz/foo2.jpg"
        }
      end
      let(:tree) { { "bar"=>{}, "baz"=>{} } }

      include_examples "proper handling"
    end

    context "exactly one file" do
      let(:files) do
        { "/tmp/foo1.jpg" => "/bar/foo1.jpg" }
      end
      let(:tree) { { "bar"=>{} } }

      it "passes file to #put_file" do
        server.should_receive(:mktree).with(tree)
        server.should_receive(:put_file).with(files.keys.first, files.values.first)
        server.put_files files
      end
    end

    context "no files" do
      let(:files) { {} }

      it "does not to anything" do
        server.should_not_receive(:put_file)
        connection.should_not_receive(:mkdir)
        server.put_files files
      end
    end
  end

  context "#directory_tree" do
    let(:files) {
      %w(/foo/bar1.jpg /foo/bar2.jpg /foo/bar/baz.jpg /foo/foo/bar.jpg /foobar/foobar.jpg /root.jpg)
    }

    it "handles empty file list" do
      expect(server.directory_tree([])).to eq({})
    end

    it "extracts nested directory structure" do
      expect(server.directory_tree(files)).to eq(
        {
          "foo" => {
            "bar" => {},
            "foo" => {}
          },
          "foobar"=>{}
        }
      )
    end
  end

  context "#mktree" do
    before do
      server.stub(:connection).and_return(connection)
    end
    let(:tree) do
      {
        "foo"=>{
          "bar"=>{},
          "baz"=>{"qux"=>{}}},
        "foobar"=>{}
      }
    end

    it "handles empty tree" do
      server.mktree({})
    end

    context "empty ftp tree" do
      it "creates entire nested tree" do
        connection.should_receive(:nlst).with("/").ordered.and_return([])
        connection.should_receive(:mkdir).with("/foo").ordered
        connection.should_receive(:mkdir).with("/foobar").ordered
        connection.should_receive(:nlst).with("/foo/").ordered.and_return([])
        connection.should_receive(:mkdir).with("/foo/bar").ordered
        connection.should_receive(:mkdir).with("/foo/baz").ordered
        connection.should_receive(:nlst).with("/foo/baz/").ordered.and_return([])
        connection.should_receive(:mkdir).with("/foo/baz/qux").ordered
        server.mktree(tree)
      end
    end

    context "partially existent ftp tree" do
      it "creates only the missing directories" do
        connection.should_receive(:nlst).with("/").ordered.and_return(["foo"])
        connection.should_receive(:mkdir).with("/foobar").ordered
        connection.should_receive(:nlst).with("/foo/").ordered.and_return(["baz"])
        connection.should_receive(:mkdir).with("/foo/bar").ordered
        connection.should_receive(:nlst).with("/foo/baz/").ordered.and_return(["qux"])
        server.mktree(tree)
      end
    end

    context "intermittent creation of directories" do
      let(:tree) do
        {
          "foo"=>{},
          "bar"=>{"foobar"=>{}}
        }
      end

      it "handles Net::FTPPermError" do
        connection.should_receive(:nlst).with("/").ordered.and_return([])
        connection.should_receive(:mkdir).with("/foo").ordered.and_raise(Net::FTPPermError)
        connection.should_receive(:mkdir).with("/bar").ordered.and_raise(Net::FTPPermError)
        connection.should_receive(:nlst).with("/bar/").ordered.and_return([])
        connection.should_receive(:mkdir).with("/bar/foobar").ordered.and_raise(Net::FTPPermError)
        server.mktree(tree)
      end
    end
  end

  context "#delete_file" do
    before do
      server.stub(:connection).and_return(connection)
    end

    it "deletes the file on the server" do
      server.connection.should_receive(:delete).with("/files/original.jpg")
      server.delete_file("/files/original.jpg")
    end

    it 'rescues from Net::FTPPermError' do
      server.connection.should_receive(:delete).with('/files/original.jpg')
        .and_raise Net::FTPPermError
      expect { server.delete_file('/files/original.jpg') }.to_not raise_error
    end
  end

  context "#rmdir_p" do
    before do
      server.stub(:connection).and_return(connection)
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
end
