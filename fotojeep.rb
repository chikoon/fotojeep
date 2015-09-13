#!/usr/bin/env ruby

require 'date'
require 'getoptlong'
require 'fileutils'
require 'RMagick'

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
      success = transfer( source, target )
      if success
        done[source] = target
      end
    end
    done
  end

  def trace(str, eol="\n")
    puts("%s%s" % [str,eol]) if !@args[:quiet] || @args[:noaction]
  end

  private

  def transfer(old_path='', new_path='')

    action  = @args[:expunge]   ? 'move' : 'copy'
    reason = ''

    if @args[:noaction]
      action  = 'test'
      reason  = ' (use --run to take action)'

    elsif File.exists?(new_path) && @args[:force].nil?
      action  = "skip-#{action}" # don't overwrite existing files unless we have the force argument set
      reason  = ' (file exists, use --force to overwrite)'
    else
      action  = "force-#{action} " if @args[:force]
    end

    trace("[#{action}] << #{old_path}")
    trace("[#{action}] >> #{new_path}#{reason}\n")

    return false if action.match(/^(test|skip)$/)

   begin

      if @args[:expunge]
        FileUtils.mv(old_path, new_path) 

      elsif @args[:force]
        FileUtils.cp_r(old_path, new_path, { :remove_destination => true } )

      else
        FileUtils.cp( old_path, new_path )

      end

    rescue => e
      fail("Error trying to #{action} #{old_path} to #{new_path}: #{e.message}")

    end

    return true

  end

  def get_filename(full_path=''); full_path.gsub(/^(.*\/)(.*)$/, '\2'); end
  def get_file_extension(full_path=''); full_path.gsub(/^(.+\.)([^.]+)$/, '\2'); end

  def get_new_filename(old_filename='')

    old_path     = @args[:source] + old_filename
    matches      = (@args[:regexp]) ? old_filename.match(/#{@args[:regexp]}/) : []

    if /\.(jpe?g|gif|png)$/.match(old_filename)
      photo      = Magick::Image.read(old_path).first
      timetaken  = photo.get_exif_by_entry('DateTimeOriginal')[0][1]
    end

    new_prefix = (timetaken) ? DateTime.strptime(timetaken, '%Y:%m:%d %H:%M:%S').strftime(@args[:prefix])
      : "%s" % File.mtime(old_path).strftime("%Y%m%d");


    extension = get_file_extension( old_filename )
    suffix    = old_filename # keep the original the original filename unless regexp is specified

    # strip out the matched expression if if matches and contains at least one group
    suffix.gsub!(/#{@args[:regexp]}/, '')  if matches.size > 1

    suffix    = "_#{suffix}" unless suffix.empty?
    suffix    = "#{suffix}.#{extension}" unless suffix.match(/\.#{extension}$/)

    suffix.gsub!(/[\s]/, '_')

    new_name   = "%s%s" % [new_prefix,suffix];
  end

	def ignore_filename(i)
    return (i[0] == '.' || (@args[:regexp] && !i.match(/#{@args[:regexp]}/)) || !/\.(jpe?g|gif|png|avi|mp4)$/i.match(i))
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

      --run       -r  <optional> Boolean: Run script, performing operations (Default: false)

      --source    -s  <optional> String:  Path to source directory (Default: current directory \".\")
      --target    -t  <required> String:  Path to target directory. Will create if needed.

      --prefix    -p  <optional> String:  File prefix format (Default: \"%Y%m%d.%H.%M.%S\")
      --match     -m  <optional> RegExp:  1. Ignore files that don't match
                                          1. Strip match from target file name
                                             (when regexp contains a /(group)/, using parentheses )

      --expunge   -x  <optional> Boolean: Perform an mv operation instead of a syscopy
      --force     -f  <optional> Boolean: Overwrite existing files in the target directory

      --help      -h  <optional> Boolean: Show this help screen
      --quiet     -q  <optional> Boolean: Hush the verbose messages

    """
      exit
    end

    def self.get_options(params={})

      opts = GetoptLong.new(
         [ '--run',       '-r',   GetoptLong::NO_ARGUMENT ],

         [ '--source',    '-s',   GetoptLong::OPTIONAL_ARGUMENT ],
         [ '--target',    '-t',   GetoptLong::OPTIONAL_ARGUMENT ],

         [ '--match',     '-m',   GetoptLong::OPTIONAL_ARGUMENT ],
         [ '--prefix',    '-p',   GetoptLong::OPTIONAL_ARGUMENT ],

         [ '--expunge',   '-x',   GetoptLong::NO_ARGUMENT ],
         [ '--force',     '-f',   GetoptLong::NO_ARGUMENT ],

         [ "--quiet",     "-q",   GetoptLong::NO_ARGUMENT ],
         [ '--help',      '-h',   GetoptLong::NO_ARGUMENT ]
       )

      opts.each { |opt, arg| params[opt.gsub!(/\-/, '').to_sym] = arg }

      self.check_options params
    end

    def self.check_options(o={})
      self.help if o[:help]

      # set source directory to current directory by default
      o[:source] = '.' unless (o[:source] && File.directory?( o[:source] ) )

      # create the target directory if it doesn't exist
      FileUtils::mkdir_p o[:target] if (o[:target] && !File.directory?(o[:target]) )

      [:source, :target].each{ |name|
        self.abandon("Error: The --#{name} argument is requried",1) if !o[name] || o[name].empty?
        self.abandon("Error: #{name.capitalize} directory doesn't exist" + ((o[name].empty?) ? "" : ": #{o[name]}")+'!', 1) unless File.directory?("#{o[name]}")
        o[name] = o[name] + "/" unless o[name].match(/\/$/)
      }

      self.abandon("Error: source and target directories must be different") if (o[:source] == o[:target])

      o[:prefix]    = "%Y%m%d.%H.%M.%S" unless o[:prefix]
      o[:regexp]    = o[:match]
      o[:noaction]  = !o[:run]
      o
    end

    def self.abandon (output="none", show_help=false)
      puts output
      puts self.usage if show_help
      exit
    end

  end
end

trap "SIGINT" do; puts "\nScriptus interruptus!\n"; exit; end

# instantiate class
fj = FotoJeep.new

files = fj.run

puts "Transferred %d files" % [files.keys.length] + "\n"


# Examples:
# fotojeep -s . -t output -fx -m '(.*IMG_.*_)' -p "%Y%m%d.%H%M%S_IMG" -r




