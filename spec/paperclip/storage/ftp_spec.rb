require "spec_helper"

describe Paperclip::Storage::Ftp do
  context "When passing FTP servers directly" do
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
        attachment.exists?.should be false
      end

      it "returns true if the file exists on the primary server" do
        first_server.should_receive(:file_exists?).with("/files/original/foo.jpg").and_return(true)
        attachment.should_receive(:with_primary_ftp_server).and_yield(first_server)
        attachment.exists?.should be true
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
      it "doesn't connect to the servers if there is nothing to write" do
        attachment.instance_variable_set(:@queued_for_write, {})

        attachment.should_not_receive(:with_ftp_servers)
        attachment.should_receive(:after_flush_writes).with(no_args)

        attachment.flush_writes

        attachment.queued_for_write.should == {}
      end

      it "stores the files on every server" do
        original_file = double("original_file", :path => "/tmp/original/foo.jpg")
        thumb_file    = double("thumb_file",    :path => "/tmp/thumb/foo.jpg")

        attachment.instance_variable_set(:@queued_for_write, {
          :original => original_file,
          :thumb    => thumb_file
        })

        write_queue = {
          "/tmp/original/foo.jpg" => "/files/original/foo.jpg",
          "/tmp/thumb/foo.jpg" => "/files/thumb/foo.jpg"
        }

        first_server.should_receive(:put_files).with(write_queue)
        second_server.should_receive(:put_files).with(write_queue)

        attachment.should_receive(:with_ftp_servers).and_yield([first_server, second_server])

        attachment.should_receive(:after_flush_writes).with(no_args)

        attachment.flush_writes

        attachment.queued_for_write.should == {}
      end
    end

    context "#flush_deletes" do
      it "doesn't connect to the servers if there is nothing to delete" do
        attachment.instance_variable_set(:@queued_for_delete, [])

        attachment.should_not_receive(:with_ftp_servers)

        attachment.flush_deletes

        attachment.instance_variable_get(:@queued_for_delete).should == []
      end

      it "deletes the files on every server" do
        attachment.instance_variable_set(:@queued_for_delete, [
          "/files/original/foo.jpg",
          "/files/thumb/foo.jpg"
        ])

        first_server.should_receive(:delete_file).with("/files/original/foo.jpg")
        first_server.should_receive(:rmdir_p).with("/files/original")
        first_server.should_receive(:delete_file).with("/files/thumb/foo.jpg")
        first_server.should_receive(:rmdir_p).with("/files/thumb")
        second_server.should_receive(:delete_file).with("/files/original/foo.jpg")
        second_server.should_receive(:rmdir_p).with("/files/original")
        second_server.should_receive(:delete_file).with("/files/thumb/foo.jpg")
        second_server.should_receive(:rmdir_p).with("/files/thumb")

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
      it "returns the first configured server" do
        first_server.stub(:connected? => true)
        attachment.stub(:build_and_connect_server).and_return(first_server)
        attachment.primary_ftp_server.should == first_server
      end

      it "returns the second server if first server is down" do
        first_server.stub(:connected? => false)
        second_server.stub(:connected? => true)
        attachment.stub(:build_and_connect_server).and_return(first_server, second_server)
        attachment.primary_ftp_server.should == second_server
      end

      it "raises NoServerAvailable error if all servers are down" do
        first_server.stub(:connected? => false)
        second_server.stub(:connected? => false)
        attachment.stub(:build_and_connect_server).and_return(first_server, second_server)
        expect { attachment.primary_ftp_server }.to raise_error(Paperclip::Storage::Ftp::NoServerAvailable)
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
        first_server.stub(:connected? => true)
        second_server.stub(:connected? => true)
        attachment.stub(:build_and_connect_server).and_return(first_server, second_server)
        attachment.ftp_servers.should == [first_server, second_server]
      end

      it "raises NoServerAvailable error if all servers are down" do
        first_server.stub(:connected? => false)
        second_server.stub(:connected? => false)
        attachment.stub(:build_and_connect_server).and_return(first_server, second_server)
        expect { attachment.ftp_servers }.to raise_error(Paperclip::Storage::Ftp::NoServerAvailable)
      end
    end

    context "#build_and_connect_server" do
      it "returns a connected server instance based on the given options" do
        Paperclip::Storage::Ftp::Server.stub(:new).and_call_original

        servers = attachment.find_servers(attachment.options[:ftp_servers])
        expected_options = servers.first.merge(
          :connect_timeout       => attachment.options[:ftp_connect_timeout],
          :ignore_connect_errors => attachment.options[:ftp_ignore_failing_connections]
        )
        expect(first_server).to receive(:establish_connection)
        Paperclip::Storage::Ftp::Server.stub(:new).with(expected_options).and_return(first_server)
        attachment.build_and_connect_server(servers.first).should == first_server
      end
    end
  end

  context "When passing FTP servers as a Proc" do
    let(:attachment) do
      model_instance = double()
      model_instance.stub(:id).and_return(1)

      servers = [
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
      ]

      model_instance.stub(:image_file_name).and_return("foo.jpg")
      model_instance.stub(:ftp_credentials).and_return(servers)

      Paperclip::Attachment.new(:image, model_instance, {
        :storage => :ftp,
        :path    => "/files/:style/:filename",
        ftp_servers: -> (attachment) { attachment.instance.ftp_credentials },
        :ftp_connect_timeout => 5,
        :ftp_ignore_failing_connections => true
      })
    end

    let(:first_server)  { Paperclip::Storage::Ftp::Server.new }
    let(:second_server) { Paperclip::Storage::Ftp::Server.new }

    context "#exists?" do
      it "returns false if original_filename not set" do
        attachment.stub(:original_filename).and_return(nil)
        attachment.exists?.should be false
      end

      it "returns true if the file exists on the primary server" do
        first_server.should_receive(:file_exists?).with("/files/original/foo.jpg").and_return(true)
        attachment.should_receive(:with_primary_ftp_server).and_yield(first_server)
        attachment.exists?.should be true
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
      it "doesn't connect to the servers if there is nothing to write" do
        attachment.instance_variable_set(:@queued_for_write, {})

        attachment.should_not_receive(:with_ftp_servers)
        attachment.should_receive(:after_flush_writes).with(no_args)

        attachment.flush_writes

        attachment.queued_for_write.should == {}
      end

      it "stores the files on every server" do
        original_file = double("original_file", :path => "/tmp/original/foo.jpg")
        thumb_file    = double("thumb_file",    :path => "/tmp/thumb/foo.jpg")

        attachment.instance_variable_set(:@queued_for_write, {
          :original => original_file,
          :thumb    => thumb_file
        })

        write_queue = {
          "/tmp/original/foo.jpg" => "/files/original/foo.jpg",
          "/tmp/thumb/foo.jpg" => "/files/thumb/foo.jpg"
        }

        first_server.should_receive(:put_files).with(write_queue)
        second_server.should_receive(:put_files).with(write_queue)

        attachment.should_receive(:with_ftp_servers).and_yield([first_server, second_server])

        attachment.should_receive(:after_flush_writes).with(no_args)

        attachment.flush_writes

        attachment.queued_for_write.should == {}
      end
    end

    context "#flush_deletes" do
      it "doesn't connect to the servers if there is nothing to delete" do
        attachment.instance_variable_set(:@queued_for_delete, [])

        attachment.should_not_receive(:with_ftp_servers)

        attachment.flush_deletes

        attachment.instance_variable_get(:@queued_for_delete).should == []
      end

      it "deletes the files on every server" do
        attachment.instance_variable_set(:@queued_for_delete, [
          "/files/original/foo.jpg",
          "/files/thumb/foo.jpg"
        ])

        first_server.should_receive(:delete_file).with("/files/original/foo.jpg")
        first_server.should_receive(:rmdir_p).with("/files/original")
        first_server.should_receive(:delete_file).with("/files/thumb/foo.jpg")
        first_server.should_receive(:rmdir_p).with("/files/thumb")
        second_server.should_receive(:delete_file).with("/files/original/foo.jpg")
        second_server.should_receive(:rmdir_p).with("/files/original")
        second_server.should_receive(:delete_file).with("/files/thumb/foo.jpg")
        second_server.should_receive(:rmdir_p).with("/files/thumb")

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
      it "returns the first configured server" do
        first_server.stub(:connected? => true)
        attachment.stub(:build_and_connect_server).and_return(first_server)
        attachment.primary_ftp_server.should == first_server
      end

      it "returns the second server if first server is down" do
        first_server.stub(:connected? => false)
        second_server.stub(:connected? => true)
        attachment.stub(:build_and_connect_server).and_return(first_server, second_server)
        attachment.primary_ftp_server.should == second_server
      end

      it "raises NoServerAvailable error if all servers are down" do
        first_server.stub(:connected? => false)
        second_server.stub(:connected? => false)
        attachment.stub(:build_and_connect_server).and_return(first_server, second_server)
        expect { attachment.primary_ftp_server }.to raise_error(Paperclip::Storage::Ftp::NoServerAvailable)
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
        first_server.stub(:connected? => true)
        second_server.stub(:connected? => true)
        attachment.stub(:build_and_connect_server).and_return(first_server, second_server)
        attachment.ftp_servers.should == [first_server, second_server]
      end

      it "raises NoServerAvailable error if all servers are down" do
        first_server.stub(:connected? => false)
        second_server.stub(:connected? => false)
        attachment.stub(:build_and_connect_server).and_return(first_server, second_server)
        expect { attachment.ftp_servers }.to raise_error(Paperclip::Storage::Ftp::NoServerAvailable)
      end
    end

    context "#build_and_connect_server" do
      it "returns a connected server instance based on the given options" do
        Paperclip::Storage::Ftp::Server.stub(:new).and_call_original

        servers = attachment.find_servers(attachment.options[:ftp_servers])
        expected_options = servers.first.merge(
          :connect_timeout       => attachment.options[:ftp_connect_timeout],
          :ignore_connect_errors => attachment.options[:ftp_ignore_failing_connections]
        )
        expect(first_server).to receive(:establish_connection)
        Paperclip::Storage::Ftp::Server.stub(:new).with(expected_options).and_return(first_server)
        attachment.build_and_connect_server(servers.first).should == first_server
      end
    end
  end
end
