require "spec_helper"

describe "Integration", :integration => true do
  before do
    require "support/integration/ftp_server"
    require "support/integration/user"
    FtpServer.clear
    FtpServer.start
  end

  it "stores the attachment on the ftp servers" do
    file = File.new(File.expand_path("../support/integration/avatar.jpg", __FILE__), "rb")
    user = User.new
    user.avatar = file
    user.save!
    file.close

    File.exists?(FtpServer::HOME_PATH + "/#{user.id}/original/avatar.jpg").should be_true
  end
end
