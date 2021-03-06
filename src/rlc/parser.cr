module Parser
  class Sexp
    getter name
    getter args

    def initialize(@name, @args)
    end

    def to_s
      "(#{name}#{args.map { |a| " " + a.to_s }.join})"
    end
  end

  abstract class SexpArg
  end

  class IdentifierSexpArg < SexpArg
    getter value

    def initialize(@value : String)
    end
  end

  class NumSexpArg < SexpArg
    getter value

    def initialize(@value : Int32)
    end
  end

  class StringSexpArg < SexpArg
    getter value

    def initialize(@value : String)
    end
  end

  class Parser
    getter statements

    def initialize(@input)
      @index = 0
      @statements = [] of Sexp
    end

    def run
      loop do
        case current_token.kind
        when :eof
          break
        when :newline, :space
          consume
        else
          @statements << consume_sexp
        end
      end
    end

    def consume_sexp
      consume(:lparen)
      id = consume(:identifier)
      args = [] of Sexp | SexpArg
      loop do
        arg = try_consume_argument
        if arg
          args << arg
        else
          break
        end
      end
      consume(:rparen)
      Sexp.new(id.content, args)
    end

    def consume_all_optional_whitespace
      while [:space, :newline].includes?(current_token.kind)
        consume
      end
    end

    def try_consume_argument
      if [:space, :newline].includes?(current_token.kind)
        consume_all_optional_whitespace
        candidate = consume
        case candidate.kind
        when :identifier
          IdentifierSexpArg.new(candidate.content.to_s)
        when :number
          case candidate.content
          when /\A0x/
            NumSexpArg.new(candidate.content[2..-1].to_i(16))
          when /\A0b/
            NumSexpArg.new(candidate.content[2..-1].to_i(2))
          when /\A0/
            NumSexpArg.new(candidate.content[1..-1].to_i(8))
          else
            NumSexpArg.new(candidate.content.to_i)
          end
        when :string
          StringSexpArg.new(candidate.content.to_s)
        when :lparen
          unread_token
          consume_sexp
        else
          raise "Parser: unexpected #{candidate.kind.to_s.upcase}"
        end
      else
        nil
      end
    end

    def advance
      @index += 1
    end

    def unread_token
      @index -= 1
    end

    def current_token
      @input[@index]
    end

    def consume
      @input[@index].tap { advance }
    end

    def consume(kind)
      token = @input[@index]
      if token.kind == kind
        consume
      else
        raise "Parser: unexpected #{token.kind.to_s.upcase}"
      end
    end
  end
end
