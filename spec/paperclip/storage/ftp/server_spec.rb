require File.expand_path("../../../../spec_helper", __FILE__)

describe Paperclip::Storage::Ftp::Server do
  context "#file_exists?" do
    it "returns true if the file exists"
    it "returns false if the file does not exist"
  end
end
