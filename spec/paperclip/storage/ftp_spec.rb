require File.expand_path("../../../spec_helper", __FILE__)

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
          :password => "password1"
        },
        {
          :host     => "ftp2.example.com",
          :user     => "user2",
          :password => "password2"
        }
      ]
    })
  end

  context "#exists?" do
    it "returns false if original_filename not set" do
      attachment.stub(:original_filename).and_return(nil)
      attachment.exists?.should be_false
    end

    it "returns true if the file exists on the primary server" do
      attachment.primary_ftp_server.should_receive(:file_exists?).with("/files/original/foo.jpg").and_return(true)
      attachment.exists?.should be_true
    end

    it "accepts an optional style_name parameter to build the correct file path" do
      attachment.primary_ftp_server.should_receive(:file_exists?).with("/files/thumb/foo.jpg").and_return(true)
      attachment.exists?(:thumb)
    end
  end

  context "#to_file" do
    it "gets the file from the primary server" do
      attachment.primary_ftp_server.should_receive(:get_file).with("/files/original/foo.jpg").and_return(:foo)
      attachment.to_file.should == :foo
    end

    it "accepts an optional style_name parameter to build the correct file path" do
      attachment.primary_ftp_server.should_receive(:get_file).with("/files/thumb/foo.jpg").and_return(:foo)
      attachment.to_file(:thumb).should == :foo
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
      original_file = double("original_file")
      thumb_file    = double("thumb_file")

      attachment.instance_variable_set(:@queued_for_write, {
        :original => original_file,
        :thumb    => thumb_file
      })

      thumb_file.should_receive(:close).with(no_args)
      original_file.should_receive(:close).with(no_args)
      attachment.ftp_servers.first.should_receive(:put_file).with(original_file, "/files/original/foo.jpg")
      attachment.ftp_servers.first.should_receive(:put_file).with(thumb_file, "/files/thumb/foo.jpg")
      attachment.ftp_servers.second.should_receive(:put_file).with(original_file, "/files/original/foo.jpg")
      attachment.ftp_servers.second.should_receive(:put_file).with(thumb_file, "/files/thumb/foo.jpg")
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
      attachment.ftp_servers.first.should_receive(:delete_file).with("/files/original/foo.jpg")
      attachment.ftp_servers.first.should_receive(:delete_file).with("/files/thumb/foo.jpg")
      attachment.ftp_servers.second.should_receive(:delete_file).with("/files/original/foo.jpg")
      attachment.ftp_servers.second.should_receive(:delete_file).with("/files/thumb/foo.jpg")

      attachment.flush_deletes

      attachment.instance_variable_get(:@queued_for_delete).should == []
    end
  end

  context "#ftp_servers" do
    it "returns the configured ftp servers" do
      attachment.ftp_servers.first.host.should      == "ftp1.example.com"
      attachment.ftp_servers.first.user.should      == "user1"
      attachment.ftp_servers.first.password.should  == "password1"
      attachment.ftp_servers.second.host.should     == "ftp2.example.com"
      attachment.ftp_servers.second.user.should     == "user2"
      attachment.ftp_servers.second.password.should == "password2"
    end
  end

  context "#primary_ftp_server" do
    it "returns the first server in the list" do
      attachment.primary_ftp_server.should == attachment.ftp_servers.first
    end
  end
end
