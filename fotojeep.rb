#!/usr/bin/env ruby

require 'date'
require 'getoptlong'

class FotoJeep

	def initialize( params={} )
    @args = ScriptHandler.get_options(params)
	end

  def run
    done = {}
    for filename in Dir.entries(@args[:source])
      next if ignore_filename(filename)
      source = @args[:source]+filename
      target = @args[:target] + get_new_filename(filename)
      if transfer source, target
        done[source] = target
      end
    end
    done
  end

  def trace(str, eol="\n")
    puts("%s%s" % [str,eol]) if @args['verbose']
  end

  private

  def transfer(old_path='', new_path='')
    modified = 0
    action = ''
    if @args["no-action"]
      action  = 'test'
    elsif File.exists?(new_path) and !@args["force"]
      action  = 'skip'
    else
      action  = @args[:expunge]   ? 'move' : 'copy'
      prefix  = ( (@args[:force]) ? "force-#{action} " : "#{action}" )
      success = (@args[:expunge]) ? FileUtils.mv(old_path, new_path) : FileUtils.copy(old_path, new_path)
      if success
        modified = 1
      else
        fail("Error moving #{old_path} to #{new_path}")
      end
    end
    trace("[#{action}] << %s" % old_path)
    trace("[#{action}] >> %s" % new_path)
    modified
  end

	def get_new_filename(old_filename='')
    old_path   = @args["source"]+old_filename
    if /\.(jpe?g|gif|png)$/.match(old_filename)
      photo      = Magick::Image.read(old_path).first
      timetaken  = photo.get_exif_by_entry('DateTimeOriginal')[0][1]
    end

    new_prefix = (timetaken) ? DateTime.strptime(timetaken, '%Y:%m:%d %H:%M:%S').strftime("%Y%m%d.%H%M_")
      : "%s_" % File.mtime(old_path).strftime("%Y%m%d");

    suffix = old_filename.gsub(/^([\d]+[^\d])(.+)$/, '\2')
    #suffix     = (@args["regexp"]) ? i.match(@args["regexp"]) : i;

    new_name   = "%s%s" % [new_prefix,suffix];
	end

	def ignore_filename(i)
    r = @args[:regexp]
    return (i[0] == '.' || (r and !i[r]) || !/\.(jpe?g|gif|png|avi|mp4)$/i.match(i))
	end

  def fail(msg)
    ScriptHandler.abandon("[Boom!] #{msg}")
  end

  module ScriptHandler

    def self.usage; "Usage: ./fotojeep.rb --help"; end

    def self.help
    puts """
    FotoJeep
    Move and rename your media files 

    Usage: ./fotojeep.rb <options>

    Options:
      --target    -t  <required> String:  Path to target directory
      --source    -s  <required> String:  Path to source directory
      --regexp    -r  <optional> String:  Pattern describing original filenames to be considered.
      --expunge   -x  <optional> Boolean: Perform an mv operation instead of a syscopy
      --no-action -n  <optional> Boolean: Dry run. Perform no operations. 
      --force     -f  <optional> Boolean: Overwrite existing files in the target directory
      --help      -h  <optional> Boolean: Show this help screen
      --verbose   -v  <optional> Boolean: Show verbose messages

    """
      exit
    end

    def self.get_options(params={})
      opts = GetoptLong.new(
         [ '--target',    '-t',   GetoptLong::OPTIONAL_ARGUMENT ],
         [ '--source',    '-s',   GetoptLong::OPTIONAL_ARGUMENT ],
         [ '--regexp',    '-r',   GetoptLong::OPTIONAL_ARGUMENT ],
         [ '--expunge',   '-x',   GetoptLong::NO_ARGUMENT ],
         [ '--no-action', '-n',   GetoptLong::NO_ARGUMENT ],
         [ '--force',     '-f',   GetoptLong::NO_ARGUMENT ],
         [ "--verbose",   "-v",   GetoptLong::NO_ARGUMENT ],
         [ '--help',      '-h',   GetoptLong::NO_ARGUMENT ]
       )

      opts.each { |opt, arg| params[opt.gsub!(/\-/, '').to_sym] = arg }

      self.valid_options params
    end

    def self.valid_options(o={})
      self.help if o[:help] || (!o[:source] && !o[:target])
      # to do: create the target directory if it doesn't exist
      [:source, :target].each{ |name|
        self.abandon("Error: The --#{name} argument is requried",1) if !o[name] || o[name].empty?
        self.abandon("Error: #{name.capitalize} directory doesn't exist" + ((o[name].empty?) ? "" : ": #{o[name]}")+'!', 1) unless File.directory?("#{o[name]}")
        o[name] = o[name] + "/" unless o[name].match(/\/$/)
        puts "[#{name}] #{o[name]}" if o[:verbose]
      }
      o
    end

    def self.abandon (output="none", show_help=false)
      puts output
      puts self.usage if show_help
      exit
    end

  end
end

# instantiate class
fj = FotoJeep.new

# run transfer
files = fj.run

# done
puts "%d files modified" % [files.keys.length] + "\n"




