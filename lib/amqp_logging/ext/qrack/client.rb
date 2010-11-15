require 'qrack/client'


unless Qrack::Client.instance_methods.include?("socket_with_reliable_timeout")
  module AMQPLogging
    Timer = if RUBY_VERSION < "1.9"
              begin
                require 'system_timer'
                SystemTimer
              rescue LoadError
                require 'timeout'
                Timeout
              end
            else
              require 'timeout'
              Timeout
            end
  end

  module Qrack
    class Client
      # overwrite the timeout method so that SystemTimer is used
      # instead the standard timeout.rb: http://ph7spot.com/musings/system-timer
      delegate :timeout, :to => AMQPLogging::Timer

      def socket_with_reliable_timeout
        socket_without_reliable_timeout

        secs   = Integer(CONNECT_TIMEOUT)
        usecs  = Integer((CONNECT_TIMEOUT - secs) * 1_000_000)
        optval = [secs, usecs].pack("l_2")
      
        begin
          @socket.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
          @socket.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
        rescue Errno::ENOPROTOOPT
        end
        @socket
      end
      alias_method_chain :socket, :reliable_timeout

    end
  end
end