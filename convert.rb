require 'ostruct'
require 'optparse'

require 'rubygems'
require 'haml'
require 'sass'

module Helpers
  
  class Layout
    
    def initialize
      @contents = {}
    end
    
    def method_missing method, *args, &block
      if args.size > 0
        @contents[method] ||= []
        args.each do |file|
          @contents[method] << file
        end
      else
        @contents[method] || []
      end
    end
  
  end

end

class Converter
  
  def initialize args
    settings = OpenStruct.new
    
    OptionParser.new do |o|
      o.banner = "Usage: #{$0} -i INPUT [-l LAYOUT] [--scss SCSS,...]"
      
      o.separator ''
      
      o.on('-i', '--input INPUT', "Input HAML file") do |input|
        settings.haml = input
        settings.html = "public/#{input.split('.').first}.html"
      end
      
      o.on('-l', '--layout LAYOUT', "Layout HAML file to render INPUT with.") do |layout|
        settings.layout = "layouts/#{layout}"
      end
      
      o.on('--scss a,b,c', Array, "List of associated SCSS files to convert") do |list|
        settings.scss = list.map { |scss| "sass/#{scss}" }
        settings.css = list.map { |scss| "public/css/#{scss.split('.').first}.css" }
      end
      
      o.separator ''
      o.separator "Help:"
      
      o.on_tail('-h', '--help', "Show this message") do
        puts o
        exit
      end
    end.parse!(args)
    
    @settings = settings
  end
  
  def convert!
    if @settings.haml.nil?
      puts "Must supply an input HAML file!"
      exit
    end
    
    convert_haml
    convert_scss if @settings.scss
  end
  
  private
  
    def convert_haml
      puts "Converting #{@settings.haml} to #{@settings.html}"
      haml = File.read(@settings.haml)
      engine = Haml::Engine.new(haml)

      if @settings.layout
        puts "  Applying layout #{@settings.layout}"
        helper = Helpers::Layout.new
        ihtml = engine.render(helper)

        haml = File.read(@settings.layout)
        engine = Haml::Engine.new(haml)

        html = engine.render(helper) { ihtml }
      else
        html = engine.render
      end

      File.open(@settings.html, 'w') { |f| f.write html }
    end
    
    def convert_scss
      @settings.scss.each_with_index do |scss, index|
        puts "Converting #{scss} to #{@settings.css[index]}"
        scss = File.read(scss)
        engine = Sass::Engine.new(scss, :syntax => :scss)
        
        File.open(@settings.css[index], 'w') { |f| f.write engine.render }
      end
    end
  
end

Converter.new(ARGV).convert!
