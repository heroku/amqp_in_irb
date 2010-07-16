require 'irb'

require 'bunny'


module AMQPInIRB

class ParseOneOption
  RE = /^ +(--[^ ]+) +: *(natural|bool|string) +([^ ].+)$/
  def ParseOneOption.parse_option(name, type, array)
    if name == array[0]
      sym = name[2..-1].to_sym
      case type
      when 'string'
        arg = array[1]
        raise "No `#{type}' arg for `#{name}'." unless arg
        [{sym => arg}, array[2..-1]]
      when 'natural'
        arg = array[1]
        raise "No `#{type}' arg for `#{name}'." unless arg
        b = ! /^[0-9]+$/.match(arg).nil?
        raise "Arg `#{arg}' for `#{name}' isn't a natural number." unless b
        [{sym => arg.to_i}, array[2..-1]]
      when 'bool'
        [{sym => true}, array[1..-1]]
      end
    end
  end
  def initialize(s)
    m = RE.match(s)
    raise "Invalid option spec:\n#{s}" unless m
    @name, @type, @desc = m[1..3]
  end
  def parse(array)
    ParseOneOption.parse_option(@name, @type, array)
  end
end

def connect_and_run(params)
  ARGV.clear  # We clear ARGV so IRB won't try to parse our opts.
  begin
    $conn = Bunny.new(params)
    $conn.start
    STDERR.puts "Connection available in `$conn'."
    IRB.start
    $conn.stop
  rescue SystemExit => e
    # Do nothing.
  rescue Exception => e
    STDERR.puts "Exception (#{e.class}):\n  #{e.message}"
  end
end

def opts_from_environment
  results = []
  amqp = ENV['AMQP_URL']
  rabbit_port = ENV['RABBITMQ_NODE_PORT']
  rabbit_ip = ENV['RABBITMQ_NODE_IP_ADDRESS']
  case
  when amqp
    if rabbit_ip or rabbit_port
      STDERR.puts "Ignoring rabbit environment variables due to `AMQP_URL'."
    end
    parts = parse_AMQP_url(amqp)
    if parts.keys.empty?
      STDERR.puts "Unreadable `AMQP_URL'."
    else
      listing = parts.keys.map{|k| "`#{k}'"}.join(', ')
      STDERR.puts "Using `AMQP_URL' to set #{listing}."
      parts.each do |k, v|
        case v
        when TrueClass
          args << k
        else
          results << k << v
        end
      end
    end
  else
    if rabbit_ip
      STDERR.puts "Using `RABBITMQ_NODE_IP_ADDRESS' to set `--host'."
      results << '--host' << rabbit_ip
    end
    if rabbit_port
      STDERR.puts "Using `RABBITMQ_NODE_PORT' to set `--port'."
      results << '--port' << rabbit_port
    end
  end
  results
end

# amqp://root:pwnt@example.com/passwd
AMQP_RE = /^(amqps?):\/\/    ##  AMQP protocol scheme.
             (([^\/:@]+)     ##  User spec. ## User.
              (:([^\/@]+))?                 ## Password.
              @                             ## Closing @ sign.
             )?
             ([^\/:@]+)      ##  Host.
             (:([0-9]+))?    ##  Port.
             (\/([^\/]+))?   ##  Virtual host.
             \/?             ##  Ending slash is ending!
            $/x
def parse_AMQP_url(url)
  result = {}
  m = AMQP_RE.match(url)
  if m
    scheme, _2, user, _4, pass, host, _7, port, _9, vhost = m[1..-1]
    result['--ssl'] = true if 'amqps' == scheme
    result['--user'] = user if user
    result['--pass'] = pass if pass
    result['--host'] = host if host
    result['--port'] = port if port
    result['--vhost'] = vhost if vhost
  end
  result
end

def derive_params(option_descriptions)
  params = {}
  args = []
  parsers = option_descriptions.lines.map{|line| ParseOneOption.new(line) }
  case
  when /^amqps?:\/\/[^ ]+$/.match(ARGV.join(' '))
    parts = parse_AMQP_url(ARGV[0])
    abort "Unreadable AMQP URL argument." if parts.keys.empty?
    parts.each do |k, v|
      case v
      when TrueClass
        args << k
      else
        args << k << v
      end
    end
  else
    args = ARGV + opts_from_environment
  end
  while not args.empty?
    res = nil
    parsers.each do |parser|
      begin
        res = parser.parse(args)
      rescue RuntimeError => e
        abort e.message
      end
      if res
        hash, arr = res
        params = params.merge(hash)
        args = arr
        break
      end
    end
    abort "Failing on mysterious argument `#{args[0]}'." unless res
  end
  params
end

end

