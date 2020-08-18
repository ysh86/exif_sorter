#!/usr/bin/env ruby

#require 'rubygems'
require 'bundler/setup'
require 'exifr/jpeg'

#require 'FileUtils'
#require 'Pathname'

require 'rexml/document'


def glob_files(files, argv)
  argv.each do |path|
    case File.ftype path
    when "directory"
      Dir.foreach(path) do |file|
        # TODO ちょーーーいまいち
        glob_files files, [File.join(path, file)] if file !~ /^\.\.?$/
      end
    when "file"
      files << path if path =~ /\.(jpg|jpeg)$/i
    end
  end
end

def get_date(file)
  jpeg = EXIFR::JPEG.new(file)
  date = jpeg.exif.date_time_original if jpeg.exif?
  if date == nil
    date = File.mtime(file)
  end
  date
end

###################################
# main
###################################
if ARGV.size < 2
  STDERR.puts "Usage: #{$0} DST_DIR FILE .."
  exit
end

dst_dir = ARGV[0]
files = []
glob_files files, ARGV[1..-1]

dst_id = 1
files.sort{|x,y| get_date(x) <=> get_date(y)}.each do |file|
  # destination
  dst_file = File.join(dst_dir, "DSC#{sprintf("%05d",dst_id)}.JPG")
  dst_id += 1

  # copy
  #FileUtils.copy_file(file, dst_file, true)

  # comment
  comments = []
  xml_path = Pathname.new(file).sub_ext('.XML')
  if xml_path.exist?
    xml_doc = REXML::Document.new(xml_path.open)
    xml_doc.elements.each('/mail/text') do |e|
      comments << e.text
    end
  end

  # log
  puts "\"#{get_date(file)}\", \"#{file}\", \"#{dst_file}\""
  #puts "#{comments[0]}"
  #puts "------------------------------------------------------"
end
