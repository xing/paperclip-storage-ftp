require File.expand_path("../../../spec_helper", __FILE__)

describe Paperclip::Storage::Ftp do
  let(:attachment) do
    model_instance = double()
    model_instance.stub(:id).and_return(1)

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
      attachment.stub(:original_filename).and_return("foo.jpg")
      attachment.primary_ftp_server.should_receive(:file_exists?).with("/files/original/foo.jpg").and_return(true)
      attachment.exists?.should be_true
    end
  end

  context "#to_file"
  context "#flush_writes"
  context "#flush_deletes"
end
