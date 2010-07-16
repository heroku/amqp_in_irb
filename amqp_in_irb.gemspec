spec = Gem::Specification.new do |s|
  s.name                     =  'amqp_in_irb'
  s.version                  =  '0.1.2'
  s.summary                  =  'Interactive connection to an AMQP server.'
  s.description              =  'Interactive connection to an AMQP server.'
  s.add_dependency(             'bunny'                                       )
  s.require_path             =  'lib'
  s.bindir                   =  'bin'
  s.executables              =  %w| amqp_in_irb |
end


