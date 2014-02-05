require "spec_helper"
require "timeout"

describe "paperclip-storage-ftp", :integration => true do

  before(:all) do
    require "support/integration/ftp_server"
    require "support/integration/user"
    FtpServer.start
  end

  before(:each) do
    FtpServer.clear
  end

  let(:file) { File.new(File.expand_path("../support/integration/avatar.jpg", __FILE__), "rb") }
  let(:user) { User.new }

  let(:uploaded_file_server1)         { FtpServer::USER1_PATH + "/original/avatar.jpg" }
  let(:uploaded_file_server1_medium)  { FtpServer::USER1_PATH + "/medium/avatar.jpg"   }
  let(:uploaded_file_server1_thumb)   { FtpServer::USER1_PATH + "/thumb/avatar.jpg"    }
  let(:uploaded_file_server2)         { FtpServer::USER2_PATH + "/original/avatar.jpg" }
  let(:uploaded_file_server2_medium)  { FtpServer::USER2_PATH + "/medium/avatar.jpg"   }
  let(:uploaded_file_server2_thumb)   { FtpServer::USER2_PATH + "/thumb/avatar.jpg"    }

  it "stores the attachment on the ftp servers" do
    user.avatar = file
    user.save!

    File.exists?(uploaded_file_server1).should be_true
    File.exists?(uploaded_file_server1_medium).should be_true
    File.exists?(uploaded_file_server1_thumb).should be_true
    File.exists?(uploaded_file_server2).should be_true
    File.exists?(uploaded_file_server2_medium).should be_true
    File.exists?(uploaded_file_server2_thumb).should be_true

    file.size.should == File.size(uploaded_file_server1)
    file.size.should == File.size(uploaded_file_server2)
  end

  it "deletes an attachment from the ftp servers" do
    user.avatar = file
    user.save!

    user.destroy

    File.exists?(uploaded_file_server1).should be_false
    File.exists?(uploaded_file_server1_medium).should be_false
    File.exists?(uploaded_file_server1_thumb).should be_false
    File.exists?(uploaded_file_server2).should be_false
    File.exists?(uploaded_file_server2_medium).should be_false
    File.exists?(uploaded_file_server2_thumb).should be_false
  end

  it "survives temporarily closed ftp connections" do
    user.avatar = file
    user.save!

    user.avatar = nil
    user.save!

    FtpServer.restart

    user.avatar = file
    user.save!

    File.exists?(uploaded_file_server1).should be_true
    File.exists?(uploaded_file_server2).should be_true
  end

  it "allows ignoring failed connections" do
    user = UserIgnoringFailingConnection.new
    user.avatar = file
    expect{ user.save! }.to_not raise_error

    File.exists?(uploaded_file_server1).should be_true
    File.exists?(uploaded_file_server1_medium).should be_true
    File.exists?(uploaded_file_server1_thumb).should be_true
    File.exists?(uploaded_file_server2).should be_false
    File.exists?(uploaded_file_server2_medium).should be_false
    File.exists?(uploaded_file_server2_thumb).should be_false
  end

  it "raises a SystemCallError when not ignoring failed connections" do
    user = UserNotIgnoringFailingConnection.new
    user.avatar = file
    expect{ user.save! }.to raise_error(SystemCallError)
  end

  unless ENV['TRAVIS']
    it "allows setting a connect timeout" do
      user = UserWithConnectTimeout.new
      user.avatar = file

      # Wrap the expectation in a timeout block to make
      # sure we don't accidentally get a passing test by waiting
      # for the Errno::ETIMEDOUT raised by the OS (usually in the
      # seconds or minutes range)
      Timeout.timeout(UserWithConnectTimeout::TIMEOUT + 1) do
        expect { user.save! }.to raise_error(Errno::ETIMEDOUT)
      end
    end
  end
end
