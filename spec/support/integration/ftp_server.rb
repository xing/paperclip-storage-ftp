require "daemon_controller"

class FtpServer

  INSTALL_PATH = File.expand_path("../../../../vendor/apache-ftpserver", __FILE__)
  USER1_PATH   = INSTALL_PATH + "/res/user1"
  USER2_PATH   = INSTALL_PATH + "/res/user2"

  def self.start
    daemon_controller.start unless daemon_controller.running?
  end

  def self.restart
    daemon_controller.restart
  end

  def self.clear
    FileUtils.rm_r(Dir.glob(USER1_PATH + "/*"))
    FileUtils.rm_r(Dir.glob(USER2_PATH + "/*"))
  end

  private

  def self.daemon_controller
    @daemon_controller ||= DaemonController.new(
      :identifier     => "Apache FtpServer",
      :start_command  => "cd #{INSTALL_PATH}; ./bin/ftpd.sh res/conf/ftpd-typical.xml",
      :ping_command   => [:tcp, '127.0.0.1', 2121],
      :pid_file       => INSTALL_PATH + "/res/ftpd.pid",
      :log_file       => INSTALL_PATH + "/res/log/ftpd.log",
      :start_timeout  => 30
    )
  end
end
