require "singleton"
require "daemon_controller"

class FtpServer
  include Singleton

  INSTALL_PATH = "./vendor/apache-ftpserver-1.0.6"

  def start
    daemon_controller.start
  end

  def stop
    daemon_controller.stop
  end

  private

  def daemon_controller
    @daemon_controller ||= DaemonController.new(
      :identifier       => "Apache FtpServer",

      # TODO Write our own *daemonizing* start script
      :start_command    => "cd #{INSTALL_PATH}; ./bin/ftpd.sh res/conf/ftpd-typical.xml",

      :ping_command     => [:tcp, '127.0.0.1', 2121],
      :pid_file         => INSTALL_PATH + "/res/log/ftpd.pid",
      :log_file         => INSTALL_PATH + "/res/log/ftpd.log"
    )
  end
end
