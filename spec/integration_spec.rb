require "spec_helper"

require "support/integration/ftp_server"
require "support/integration/user"

describe "Integration" do
  before { FtpServer.start }
  after  { FtpServer.stop }

  it "stores the attachment on the ftp server" do
    user = User.new
    # user.avatar =
    user.save!
  end
end
