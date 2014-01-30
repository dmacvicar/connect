require 'optparse'

class SUSE::Connect::Cli

  attr_reader :options

  def initialize(argv)
    @options = {}
    extract_options
    execute!
  end

  private

    def extract_options

      OptionParser.new do |opts|
        opts.banner = 'Usage: SUSEConnect [options]'

        opts.on('-h', '--host [HOST]', 'Connection host.') do |opt|
          check_if_param(opt, 'Please provide host parameter')
          @options[:host] = opt
        end

        opts.on('-p', '--port [PORT]', 'Connection port.') do |opt|
          check_if_param(opt, 'Please provide port parameter')
          @options[:port] = opt
        end

        opts.on('-t', '--token [TOKEN]', 'Registration token.') do |opt|
          check_if_param(opt, 'Please provide token parameter')
          @options[:token] = opt
        end

        opts.on('-k', '--insecure', 'Print version') do |opt|
          @options[:insecure] = opt
        end

        opts.separator ''
        opts.separator 'Common options:'

        opts.on('-d', '--dry-mode', 'Dry mode. Does not make any changes to the system.') do |opt|
          @options[:dry] = opt
        end

        opts.on_tail('--version', 'Print version') do
          puts SUSE::Connect::VERSION
          exit
        end

        opts.on_tail('--help', 'Show this message.') do
          puts opts
          exit
        end

        opts.on('-v', '--verbose', 'Run verbosely.') do |opt|
          @options[:verbose] = opt
        end

      end.parse!

    end

    def execute!
      # TODO: pass only what is needed
      SUSE::Connect::Client.new(@options).execute!
    end

    def check_if_param(opt, message)
      unless opt
        puts message
        exit 1
      end
    end

end
