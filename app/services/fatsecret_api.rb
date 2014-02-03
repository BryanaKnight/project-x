require "openssl"
require "base64"
require "digest/md5"
require "net/http"

class String
  def esc
      CGI.escape(self).gsub("%7E", "~").gsub("+", "%20")
  end
end

class FatsecretAPI
  # attr_accessible :title, :body

  KEY = ENV["FATSECRET_KEY"]
  SECRET = ENV["FATSECRET_SECRET"]
  SHA1 = "HMAC-SHA1"
  SITE = "http://platform.fatsecret.com/rest/server.api"

  def self.search(expression)
    results = JSON.parse(return_json_search(expression))
    results["foods"]["food"].map do |f|
      Foods::SearchItem.new(f["food_name"], f["food_id"], f["food_description"])
    end
  end

  def self.return_json_search(expression)
    new_params = {
      :method => 'foods.search',
      :search_expression => expression,
      :format => 'json'
    }
    make_request(new_params)
  end

  def self.make_request(new_params)
    Net::HTTP.get(build_uri(new_params))
  end

  def self.build_uri(new_params)
    params = new_params.merge(self.common_params)
    sorted_params = params.sort {|a, b| a.first.to_s <=> b.first.to_s}
    base = base_string("GET", sorted_params)
    http_params = http_params("GET", params)
    sig = sign(base).esc
    uri_for(http_params, sig)
  end

  def self.common_params
    {
      :oauth_consumer_key => KEY,
      :oauth_nonce => Digest::MD5.hexdigest(rand(11).to_s),
      :oauth_signature_method => SHA1,
      :oauth_timestamp => Time.now.to_i,
      :oauth_version => "1.0"
    }
  end

  def self.base_string(http_method, param_pairs)
    param_str = param_pairs.collect{|pair| "#{pair.first}=#{pair.last}"}.join('&')
    list = [http_method.esc, SITE.esc, param_str.esc]
    list.join("&")
  end

  def self.http_params(method, args)
    pairs = args.sort {|a, b| a.first.to_s <=> b.first.to_s}
    list = []
    pairs.inject(list) {|arr, pair| arr << "#{pair.first.to_s}=#{pair.last}"}
    list.join("&")
  end

  def self.sign(base, token='')
    secret = "#{SECRET.esc}&#{token.esc}"
    base64 = Base64.encode64(OpenSSL::HMAC.digest('sha1',secret, base)).gsub(/\n/,'')
  end

  def self.uri_for(params, signature)
    parts = params.split('&')
    parts << "oauth_signature=#{signature}"
    URI.parse("#{SITE}?#{parts.join('&')}")
  end

end