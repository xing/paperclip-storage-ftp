require "spec_helper"

require "support/integration/ftp_server"
require "support/integration/user"

describe "Integration" do
  before { FtpServer.instance.start }
  after  { FtpServer.instance.stop }

  it "saves the attachment" do
    user = User.new
    # user.avatar =
    user.save!
  end
end
