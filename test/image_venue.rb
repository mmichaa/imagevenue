#!/bin/env/ruby

$LOAD_PATH.insert(0, File.expand_path(File.dirname(__FILE__) + '/../lib'))

$USER = ENV['IVU'] || 'img13340'
$PASS = ENV['IVP'] || '77584d27'

require 'image_venue'

describe ImageVenue do
  it "should be logged in" do
    connection = ImageVenue::login($USER, $PASS)
    connection.should be_a ImageVenue::Connection
    connection.logged_in?.should be true
  end

  it "should not be logged in" do
    connection = ImageVenue::login($USER, $PASS + "xxx")
    connection.should be_a ImageVenue::Connection
    connection.logged_in?.should be false
  end
end

describe ImageVenue::Connection do
end

describe ImageVenue::Directory do
  before(:all) do
    @connection = ImageVenue::login($USER, $PASS)
  end

  it "should be empty" do
    ImageVenue::Directory.list(@connection).each do |directory|
      directory.destroy.should be true
    end
  end

  it "should be created" do
    directory = ImageVenue::Directory.new(@connection, 'should_be_created')
    directory.is_new?.should be true
    directory.save(true).should be true
    directory.is_new?.should be false
  end

  it "should be in list" do
    directories = ImageVenue::Directory.list(@connection)
    directories.should be_a Array
    directories.should have(1).item
    directory = directories.first
    directory.should be_a ImageVenue::Directory
    directory.is_new?.should be false
    directory.name.should eql 'should_be_created'
  end

  it "should be deleted" do
    directories = ImageVenue::Directory.list(@connection)
    directory = directories.first
    directory.should be_a ImageVenue::Directory
    directory.is_new?.should be false
    directory.destroy(true).should be true
  end

  it "should not be in list" do
    directories = ImageVenue::Directory.list(@connection)
    directories.should be_a Array
    directories.should have(0).items
  end
end

describe ImageVenue::File do
  before(:all) do
    @connection = ImageVenue::login($USER, $PASS)
    @directory = ImageVenue::Directory.new(@connection, 'ruby')
    @directory.save(true)
  end

  it "should be empty" do
    ImageVenue::File.list(@directory).each do |file|
      file.destroy.should be true
    end
  end

  it "should be created" do
    file = ImageVenue::File.new(@directory, 'ruby-icon.jpg')
    file.is_new?.should be true
    file.save.should be true
    file.is_new?.should be false
  end

  it "should be in list" do
    files = ImageVenue::File.list(@directory)
    files.should be_a Array
    files.should have(1).item
    file = files.first
    file.should be_a ImageVenue::File
    file.is_new?.should be false
    file.real_name.should eql 'ruby-icon.jpg'
  end

  it "should match thumbnail url" do
    file = ImageVenue::File.list(@directory).first
    file.thumnail_url.should match /^http/
  end

  it "should match large url" do
    file = ImageVenue::File.list(@directory).first
    file.large_url.should match /^http/
  end

  it "should be deleted" do
    files = ImageVenue::File.list(@directory)
    file = files.first
    file.should be_a ImageVenue::File
    file.is_new?.should be false
    file.destroy.should be true
  end

  it "should not be in list" do
    files = ImageVenue::File.list(@directory)
    files.should be_a Array
    files.should have(0).items
  end
end