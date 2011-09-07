module ChildProcessManager
  module OS
    class OpenFile
      def self.lsof(filter)
        `lsof -w #{ filter } -Pn`
      end

      def self.listening_tcp_fds
        lsof('-iTCP -sTCP:LISTEN').lines.drop(1).map { |l| parse_lsof_line(l) }
      end

      def self.tcp_port(port, host = '127.0.0.1')
        listening_tcp_fds.select { |f| f.listens_on?(port, host) }
      end

      HEADER = [:command, :pid, :user, :fd, :type, :device, :size, :node, :name]

      def self.parse_lsof_line(line)
        header  = [:command, :pid, :user, :fd, :type, :device, :size, :node, :name]
        columns = line.split(/\s+/)

        # Last column may contain spaces
        columns[8] = columns[8..-1].join(' ')

        new(Hash[HEADER.zip(columns)])
      end

      attr_accessor *HEADER

      def initialize(options = {})
        options.each do |key, value|
          method("#{ key }=").call(value)
        end
      end

      def pid
        Integer(@pid)
      end

      def listens_on?(port, host = '127.0.0.1')
        name =~ /^(.+?):([\d]+)/

        return ($1 == '*' && Integer($2) == port) || ($1 == host && port == Integer($2))
      end

      def inspect
        "#<FD:#{ type } process=#{ @command } user=#{ @user } listen=#{ @name }>"
      end
    end
  end
end
