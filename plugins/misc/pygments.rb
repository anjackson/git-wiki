author      'Daniel Mendler'
description 'Pygments syntax highlighter'
require     'open3'

module ::Pygments
  PROGRAM = 'pygmentize'
  RUN_OPTIONS = '-O encoding=utf8 -O linenos=table -f html -l'
  LOOKUP_OPTIONS = '-L lexer'

  def self.installed?
    !lexer_mapping.empty?
  end

  def self.pygmentize(text, options = {})
    if options[:format].blank? && options[:filename].blank?
      raise ArgumentError, 'Either format or filename must be supplied'
    end

    format = options[:filename] ? find_lexer(options[:filename]) : options[:format]
    return "<pre>#{escape_html(content.strip)}</pre>" if !format
    run(text, format)
  end

  def self.supports?(filename)
    !!find_lexer(filename)
  end

  def self.run(text, format)
    content = Open3.popen3("#{PROGRAM} #{RUN_OPTIONS} '#{format}'") { |stdin, stdout, stderr|
      stdin << text
      stdin.close
      stdout.read
    }
    content.blank? ? "<pre>#{escape_html(text.strip)}</pre>" : content
  end

  @mapping = nil

  def self.lexer_mapping
    if !@mapping
      @mapping = {}
      lexer = ''
      output = `#{PROGRAM} #{LOOKUP_OPTIONS}`
      output.split("\n").each do |line|
        if line =~ /^\* ([^:]+):$/
          lexer = $1.split(', ').first
        elsif line =~ /^   [^(]+ \(filenames ([^)]+)/
          $1.split(', ').each {|s| @mapping[s] = lexer }
        end
      end
    end
    @mapping
  end

  def self.find_lexer(name)
    pattern = lexer_mapping.keys.find {|pattern| File.fnmatch(pattern, name)}
    pattern && lexer_mapping[pattern]
  end

  private_class_method :lexer_mapping, :find_lexer, :run
end

setup do
  raise(RuntimeError, 'pygments is not installed') if !Pygments.installed?

  class Wiki::App
    add_hook(:after_head) do
      '<link rel="stylesheet" href="/sys/misc/pygments.css" type="text/css"/>'
    end

    public_files 'pygments.css'
  end
end
