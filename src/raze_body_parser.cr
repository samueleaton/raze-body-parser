require "raze"
require "./raze_body_parser/*"

class HTTP::Server::Context
  macro finished
    getter body : HTTP::Params | Nil
  end

  def parse_urlencoded_body
    params = request.body
    if params
      @body = HTTP::Params.parse(params.gets_to_end)
    else
      @body = HTTP::Params.parse("")
    end
  end
end

class Raze::BodyParser < Raze::Handler
  @parser_type = ""

  def initialize(parser_type : String)
    parser_types = {"urlencoded", "json"}
    if parser_types.includes? parser_type
      @parser_type = parser_type
    else
      raise "Invalid parser_type given to Raze::BodyParser.new. It must be \"#{parser_types.join("\" or \"")}\""
    end
  end

  def call(ctx, done)
    return unless content_type = ctx.request.headers["Content-Type"]?
    if @parser_type == "urlencoded" && content_type.starts_with?("application/x-www-form-urlencoded")
      ctx.parse_urlencoded_body
    end
    done.call
  end
end


body_parsers = {Raze::BodyParser.new("urlencoded"), Raze::BodyParser.new("json")}

# using tuple splat you can combine multiple body parsers on one route
post "/yee", *body_parsers do |ctx|
  body = ctx.body
  puts "name: #{body["name"]}" if body
  "ok "
end

Raze.run
