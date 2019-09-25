require "email_parser/version"
require "strscan"

class EmailParser
  class Error < StandardError; end
  class ParseError < Error; end

  LETTER_AND_DIGIT = (("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a).join.freeze
  QUOTE_NOT_REQUIRED_SYMBOLS = "!#$%&'*+-/=?^_`{|}~".freeze
  QUOTE_REQUIRED_SYMBOLS = "()<>[]:;@,. ".freeze
  ESCAPE_REQUIRED_SYMBOLS = %(\\").freeze

  QUOTE_NOT_REQUIRED_CHARS = Regexp.new(
    "[#{Regexp.escape(LETTER_AND_DIGIT + QUOTE_NOT_REQUIRED_SYMBOLS)}]+",
  )
  QUOTE_REQUIRED_CHARS = Regexp.new(
    "(" \
    "[#{Regexp.escape(LETTER_AND_DIGIT + QUOTE_NOT_REQUIRED_SYMBOLS + QUOTE_REQUIRED_SYMBOLS)}]" \
    "|" \
    "\\\\[#{Regexp.escape(LETTER_AND_DIGIT + QUOTE_NOT_REQUIRED_SYMBOLS + QUOTE_REQUIRED_SYMBOLS + ESCAPE_REQUIRED_SYMBOLS)}]" \
    ")+",
  )

  attr_reader :allow_address_literal, :allow_dot_sequence_in_local, :allow_local_begin_with_dot, :allow_local_end_with_dot

  def self.parse(src, **options)
    new(**options).parse(src)
  end

  def self.valid?(src, **options)
    new(**options).valid?(src)
  end

  def initialize(allow_address_literal: false, allow_dot_sequence_in_local: false, allow_local_begin_with_dot: false, allow_local_end_with_dot: false)
    @allow_address_literal = allow_address_literal
    raise NotImplementedError("Sorry, `allow_address_literal == true` is not supported yet") if allow_address_literal

    @allow_dot_sequence_in_local = allow_dot_sequence_in_local
    @allow_local_begin_with_dot = allow_local_begin_with_dot
    @allow_local_end_with_dot = allow_local_end_with_dot
  end

  def valid?(src)
    parse(src)
    true
  rescue ParseError
    false
  end

  def parse(src)
    s = StringScanner.new(src)
    se = [:mailbox]

    raise ParseError unless push!(se, local_part(s))
    raise ParseError unless push!(se, s.scan(/@/))
    raise ParseError unless push!(se, domain_or_address_literal(s))
    raise ParseError unless s.eos?

    se
  end

  private
  def push!(array, val)
    return if val.nil?

    array << val
    val
  end

  def local_part(s)
    se = [:local_part]
    return unless push!(se, quoted_string(s) || dot_string(s))

    se
  end

  def quoted_string(s)
    se = [:quoted_string]

    return unless push!(se, dquote(s))
    return unless push!(se, s.scan(QUOTE_REQUIRED_CHARS))
    return unless push!(se, dquote(s))

    se
  end

  def dquote(s)
    se = [:dquote]
    return unless push!(se, s.scan(/"/))

    se
  end

  def dot(s)
    se = [:dot]
    return unless push!(se, s.scan(/\./))

    se
  end

  def atom(s)
    se = [:atom]
    return unless push!(se, s.scan(QUOTE_NOT_REQUIRED_CHARS))

    se
  end

  def dot_string(s)
    se = [:dot_string]

    case
    when push!(se, dot(s))
      return unless allow_local_begin_with_dot
    when push!(se, atom(s))
      # noop
    else
      return
    end

    dot_seq = 0

    loop do
      case
      when push!(se, dot(s))
        dot_seq += 1
        return if dot_seq > 1 && !allow_dot_sequence_in_local

        next
      when push!(se, atom(s))
        dot_seq = 0
      else
        break
      end
    end

    return if dot_seq > 0 && !allow_local_end_with_dot

    se
  end

  def domain_or_address_literal(s)
    if s.scan(/\[/)
      return unless allow_address_literal
      # TODO: parse address literal
    else
      domain(s)
    end
  end

  # https://tools.ietf.org/html/rfc1035 p7
  def domain(s)
    se = [:domain]
    return unless push!(se, subdomain(s))

    se
  end

  def subdomain(s)
    se = [:subdomain]

    return unless push!(se, label(s))

    loop do
      break unless push!(se, dot(s))
      raise ParseError unless push!(se, label(s))
    end

    se
  end

  def label(s)
    buffer = ""
    return unless push!(buffer, s.scan(/[a-zA-Z]/))

    push!(buffer, s.scan(/[a-zA-Z0-9]+/))
    push!(buffer, s.scan(/(-[a-zA-Z0-9])+/))

    [:label, buffer]
  end
end
