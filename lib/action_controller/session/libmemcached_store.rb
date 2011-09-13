begin
  require_library_or_gem 'memcached'
  require 'thread'
  module ActionController
    module Session
      class LimemcachedStore < AbstractStore
        def initialize(app, options = {})
          # Support old :expires option
          options[:expire_after] ||= options[:expires]

          super

          @pool = options[:cache]
          @mutex = Mutex.new

          super
        end

        private
          def get_session(env, sid)
            sid ||= generate_sid
            begin
              session = @pool.get(sid) || {}
            rescue Memcached::ConnectionFailure, Errno::ECONNREFUSED
              session = {}
            end
            [sid, session]
          end

          def set_session(env, sid, session_data)
            options = env['rack.session.options']
            expiry  = options[:expire_after] || 0
            @pool.set(sid, session_data, expiry)
            return true
          rescue Memcached::ConnectionFailure, Errno::ECONNREFUSED
            return false
          end
          
          def destroy(env)
            if sid = current_session_id(env)
              @pool.delete(sid)
            end
          rescue Memcached::ConnectionFailure, Errno::ECONNREFUSED
            false
          end
          
      end
    end
  end
rescue LoadError
  # MemCache wasn't available so neither can the store be
end
