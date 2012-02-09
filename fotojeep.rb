#!/usr/bin/ruby

$LOAD_PATH.unshift(".")

#require 'net/http'
require 'date'
require 'fileutils'
require 'getoptlong'
require 'RMagick'

class Argie
  
  
  def initialize()
    @class_name   = "Argie"
  end

  def default_options
    {
      "target"    => '/Users/chikoon/Pictures/incoming/_to-adjust/',
      "source"    => '/Volumes/Olympus/DCIM/100OLYMP/',
      "regexp"    => /^(.+)$/, #/(\d{3}\.[^\.]+)$/,
      "no-action" => false,
      "force"     => false,
      "expunge"   => false,
      "verbose"   => false
    }
  end

  def help
    default_args_string = "\t%s" % [default_options.collect{ |k, v| "#{k}=#{v}" }.join("\n\t")]
  """
  FotoJeep

  Usage: ./fotojeep.rb <options>
  
  Options:
    --target    -t  <required> String: Path to local directory
    --source    -s  <optional> String: Path to source directory
    --regexp    -r  <optional> String: Pattern describing original filenames to be considered.
    --expunge   -x  <optional> Boolean: Perform an mv operation (default->false does a syscopy)
    --no-action -n  <optional> Boolean: Perform no operations.  Just traces.
    --force     -f  <optional> Boolean: Overwrite existing files in to-dir
    --help      -h  <optional> Show this screen
    --verbose   -v  <optional> Show verbose messages

  Defaults:
    #{default_args_string}
    
  """
  end
  
  def get_options(params={})
    options = default_options.merge!(params)
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
    opts.each do |opt, arg|  
      case opt
        when '--target'
          dir_or_die(arg, "Target directory")
          options["target"]  = arg
        when '--source'  
          dir_or_die(arg, "Source directory")
          options["source"]  = arg
        when '--regexp'    then options["regexp"]    = arg
        when '--expunge'   then options["expunge"]   = true
        when '--no-action' then options["no-action"] = true
        when '--force'     then options["force"] = true  
        when '--verbose'   then options["verbose"] = true  
        when '--help'      then display help
      end  
    end
    options
  end
  
  def dir_or_die(path='', name="Directory")
    if !File.directory?(path)
      display("#{name} doesn't exist: #{path}")
    end
  end
  
  def display (output="none")
    puts output  
    exit
  end

end

class FotoJeep
  
	def initialize( params={} )
      arg_handler     = Argie.new
      @args           = arg_handler.get_options(params)    
      @args["source"] = slash_dir(@args["source"])
      @args["target"] = slash_dir(@args["target"])
	end
	
	def trace(str, eol="\n")
      puts("[trace] %s%s" % [str,eol])
	end
	
	def slash_dir(path='')
		if !path.match(/\/$/)
			path = path + "/"
		end
		path
	end
	
	def get_old_path(i='')
      @args["source"]+i
	end
	
	def get_new_path(i='')
      old_path   = @args["source"]+i

      if /\.(jpe?g|gif|png)$/i.match(old_path)
        photo      = Magick::Image.read(old_path).first
        timetaken  = photo.get_exif_by_entry('DateTimeOriginal')[0][1]
      end
      
      new_prefix = (timetaken) ? DateTime.strptime(timetaken, '%Y:%m:%d %H:%M:%S').strftime("%Y%m%d.%H%M_")
        : "%s_" % File.mtime(old_path).strftime("%Y%m%d");
      
      suffix = i.gsub(/^([\d]+[^\d])(.+)$/, '\2')
      #suffix     = (@args["regexp"]) ? i.match(@args["regexp"]) : i;
      
      new_name   = "%s%s" % [new_prefix,suffix];
      new_path   = "%s%s" % [@args["target"],new_name]
	end
	
	def ignore_filename(i)
      r = @args["regexp"]
      return (i[0] == '.' || (r and !i[r]) || !/\.(jpe?g|gif|png|avi|mp4)$/i.match(i))
	end
	
	def run
      reg_exp  = @args["regexp"]
      from_dir = @args["source"]
      r = []
      for i in Dir.entries(from_dir)
        if ignore_filename(i)
          next
        end
        old_path   = get_old_path(i)
        new_path   = get_new_path(i)
        transfer old_path, new_path
        r.push(from_dir + i)
      end
      r
	end
	
	def transfer(old_path='', new_path='')
      trace_prefix = ''
      ok           = nil
      if @args["no-action"]
        trace_prefix  = '[test] '
      elsif File.exists?(new_path) and !@args["force"]
        trace_prefix  = '[skip] '
        ok            = "file exists %s" % new_path;
      elsif @args["expunge"]
        trace_prefix = ( (@args["force"]) ? '[force-move] ' : '[move]' )
        ok = FileUtils.mv(old_path, new_path);
      else
        trace_prefix  = ( (@args["force"]) ? '[force-copy] ' : '[copy]' )
        ok            = FileUtils.copy(old_path, new_path);
      end
      trace("<< %s" % old_path);
      trace(">> %s" % new_path);
      if !ok
        trace("error => %s" % ok.to_s)
      end
	end
end

# instantiate class
fj = FotoJeep.new

# run transfer
files = fj.run

# done
fj.trace("%d files found" % [files.length]);




