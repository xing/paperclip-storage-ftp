require "spec_helper"

describe Paperclip::Storage::Ftp do
  let(:attachment) do
    model_instance = double()
    model_instance.stub(:id).and_return(1)
    model_instance.stub(:image_file_name).and_return("foo.jpg")

    Paperclip::Attachment.new(:image, model_instance, {
      :storage => :ftp,
      :path    => "/files/:style/:filename",
      :ftp_servers => [
        {
          :host     => "ftp1.example.com",
          :user     => "user1",
          :password => "password1",
          :port     => 2121
        },
        {
          :host     => "ftp2.example.com",
          :user     => "user2",
          :password => "password2",
          :passive  => true
        }
      ],
      :ftp_connect_timeout => 5,
      :ftp_ignore_failing_connections => true
    })
  end

  let(:first_server)  { Paperclip::Storage::Ftp::Server.new }
  let(:second_server) { Paperclip::Storage::Ftp::Server.new }

  context "#exists?" do
    it "returns false if original_filename not set" do
      attachment.stub(:original_filename).and_return(nil)
      attachment.exists?.should be_false
    end

    it "returns true if the file exists on the primary server" do
      first_server.should_receive(:file_exists?).with("/files/original/foo.jpg").and_return(true)
      attachment.should_receive(:with_primary_ftp_server).and_yield(first_server)
      attachment.exists?.should be_true
    end

    it "accepts an optional style_name parameter to build the correct file path" do
      first_server.should_receive(:file_exists?).with("/files/thumb/foo.jpg").and_return(true)
      attachment.should_receive(:with_primary_ftp_server).and_yield(first_server)
      attachment.exists?(:thumb)
    end
  end

  context "#to_file" do
    it "returns the file from the primary server as a local tempfile" do
      tempfile = double("tempfile")
      tempfile.should_receive(:path).and_return("/tmp/foo")
      tempfile.should_receive(:rewind).with(no_args)
      Tempfile.should_receive(:new).with(["foo", ".jpg"]).and_return(tempfile)
      first_server.should_receive(:get_file).with("/files/original/foo.jpg", "/tmp/foo").and_return(:foo)
      attachment.should_receive(:with_primary_ftp_server).and_yield(first_server)
      attachment.to_file.should == tempfile
    end

    it "accepts an optional style_name parameter to build the correct file path" do
      tempfile = double("tempfile")
      tempfile.should_receive(:path).and_return("/tmp/foo")
      tempfile.should_receive(:rewind).with(no_args)
      Tempfile.should_receive(:new).with(["foo", ".jpg"]).and_return(tempfile)
      first_server.should_receive(:get_file).with("/files/thumb/foo.jpg", anything)
      attachment.should_receive(:with_primary_ftp_server).and_yield(first_server)
      attachment.to_file(:thumb)
    end

    it "gets an existing file object from the local write queue, if available" do
      file = double("file")
      file.should_receive(:rewind)
      attachment.instance_variable_set(:@queued_for_write, {:original => file})
      attachment.to_file.should == file
    end
  end

  context "#flush_writes" do
    it "stores the files on every server" do
      original_file = double("original_file", :path => "/tmp/original/foo.jpg")
      thumb_file    = double("thumb_file",    :path => "/tmp/thumb/foo.jpg")

      attachment.instance_variable_set(:@queued_for_write, {
        :original => original_file,
        :thumb    => thumb_file
      })

      first_server.should_receive(:put_file).with("/tmp/original/foo.jpg", "/files/original/foo.jpg")
      first_server.should_receive(:put_file).with("/tmp/thumb/foo.jpg", "/files/thumb/foo.jpg")
      second_server.should_receive(:put_file).with("/tmp/original/foo.jpg", "/files/original/foo.jpg")
      second_server.should_receive(:put_file).with("/tmp/thumb/foo.jpg", "/files/thumb/foo.jpg")

      attachment.should_receive(:with_ftp_servers).and_yield([first_server, second_server])

      attachment.should_receive(:after_flush_writes).with(no_args)

      attachment.flush_writes

      attachment.queued_for_write.should == {}
    end
  end

  context "#flush_deletes" do
    it "deletes the files on every server" do
      attachment.instance_variable_set(:@queued_for_delete, [
        "/files/original/foo.jpg",
        "/files/thumb/foo.jpg"
      ])

      first_server.should_receive(:delete_file).with("/files/original/foo.jpg")
      first_server.should_receive(:delete_file).with("/files/thumb/foo.jpg")
      second_server.should_receive(:delete_file).with("/files/original/foo.jpg")
      second_server.should_receive(:delete_file).with("/files/thumb/foo.jpg")

      attachment.should_receive(:with_ftp_servers).and_yield([first_server, second_server])

      attachment.flush_deletes

      attachment.instance_variable_get(:@queued_for_delete).should == []
    end
  end

  context "#copy_to_local_file" do
    before do
      attachment.should_receive(:with_primary_ftp_server).and_yield(first_server)
    end

    it "returns the file from the primary server and stores it in the path specified" do
      first_server.should_receive(:get_file).with("/files/original/foo.jpg", "/local/foo").and_return(:foo)
      attachment.copy_to_local_file(:original, "/local/foo").should == :foo
    end

    it "accepts the style parameter to build the correct path" do
      first_server.should_receive(:get_file).with("/files/thumb/foo.jpg", "/local/thumb/foo")
      attachment.copy_to_local_file(:thumb, "/local/thumb/foo")
    end
  end

  context "#with_primary_ftp_server" do
    it "yields the primary ftp server, closes the connection afterwards" do
      attachment.stub(:primary_ftp_server).and_return(first_server)
      first_server.should_receive(:close_connection).ordered
      expect { |b| attachment.with_primary_ftp_server(&b) }.to yield_with_args(first_server)
    end
  end

  context "#primary_ftp_server" do
    it "returns the first server in the list" do
      attachment.stub(:ftp_servers).and_return([first_server, second_server])
      attachment.primary_ftp_server.should == attachment.ftp_servers.first
    end
  end

  context "#with_ftp_servers" do
    it "yields the ftp servers, closes the connections afterwards" do
      attachment.stub(:ftp_servers).and_return([first_server, second_server])
      first_server.should_receive(:close_connection).ordered
      second_server.should_receive(:close_connection).ordered
      expect { |b| attachment.with_ftp_servers(&b) }.to yield_with_args([first_server, second_server])
    end
  end

  context "#ftp_servers" do
    it "returns the configured ftp servers" do
      Paperclip::Storage::Ftp::Server.any_instance.stub(:establish_connection)
      Paperclip::Storage::Ftp::Server.any_instance.stub(:connected?).and_return(true)

      attachment.ftp_servers.first.host.should                   == "ftp1.example.com"
      attachment.ftp_servers.first.user.should                   == "user1"
      attachment.ftp_servers.first.password.should               == "password1"
      attachment.ftp_servers.first.port.should                   == 2121
      attachment.ftp_servers.first.connect_timeout.should        == 5
      attachment.ftp_servers.first.ignore_connect_errors.should  == true
      attachment.ftp_servers.second.host.should                  == "ftp2.example.com"
      attachment.ftp_servers.second.user.should                  == "user2"
      attachment.ftp_servers.second.password.should              == "password2"
      attachment.ftp_servers.second.passive.should               == true
      attachment.ftp_servers.second.connect_timeout.should       == 5
      attachment.ftp_servers.second.ignore_connect_errors.should == true
    end
  end
end
