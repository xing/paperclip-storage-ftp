require "daemon_controller"

class FtpServer

  INSTALL_PATH = File.expand_path("../../../../vendor/apache-ftpserver", __FILE__)

  def self.start
    daemon_controller.start
  end

  def self.stop
    daemon_controller.stop
  end

  private

  def self.daemon_controller
    @daemon_controller ||= DaemonController.new(
      :identifier     => "Apache FtpServer",
      :start_command  => "cd #{INSTALL_PATH}; ./bin/ftpd.sh res/conf/ftpd-typical.xml",
      :ping_command   => [:tcp, '127.0.0.1', 2121],
      :pid_file       => INSTALL_PATH + "/res/ftpd.pid",
      :log_file       => INSTALL_PATH + "/res/log/ftpd.log"
    )
  end
end
