require 'appfigures/version'
require 'appfigures/connection'
require 'date'
require 'mechanize'

class Appfigures
  
  attr_reader :connection
  def initialize(options = {})
    @username = options[:username]
    @password = options[:password]
    @mechanize = Mechanize.new
    @connection = Appfigures::Connection.new options[:username], options[:password]
  end

  def login
    url = "https://appfigures.com/login"
    page = self.mechanize.get(url)
    form = page.forms.first
    form['email'] = @username
    form['pass'] = @password
    page = form.submit
  end

  def product_sales
    self.connection.get('sales/products').body.map do |id, hash|
      Hashie::Mash.new({
        'ref_no'          => hash['product']['ref_no'],
        'product_id'      => hash['product']['id'],
        'store_id'        => hash['product']['store_id'],
        'store_name'      => hash['product']['store_name'],
        'name'            => hash['product']['name'],
        'sku'             => hash['product']['sku'],
        'downloads'       => hash['downloads'].to_i,
        'returns'         => hash['returns'].to_i,
        'updates'         => hash['updates'].to_i,
        'net_downloads'   => hash['net_downloads'].to_i,
        'promos'          => hash['promos'].to_i,
        'gift_redemptions'=> hash['gift_redemptions'].to_i,
        'revenue'         => hash['revenue'].to_f
      })
    end
  end

  def date_sales(start_date, end_date)
    url = "sales/dates+products/#{start_date.strftime('%Y-%m-%d')}/#{end_date.strftime('%Y-%m-%d')}"
    self.connection.get(url).body.map do |date, product|
      product.map do |product_id, hash|
        Hashie::Mash.new({
          'date'            => Date.parse(date),
          'ref_no'      => hash['product']['ref_no'],
          'product_id'      => hash['product']['id'],
          'store_id'        => hash['product']['store_id'],
          'store_name'      => hash['product']['store_name'],
          'name'            => hash['product']['name'],
          'sku'             => hash['product']['sku'],
          'product_type'    => hash['product']['product_type'],
          'parent_id'    => hash['product']['parent_id'],
          'downloads'       => hash['downloads'].to_i,
          'returns'         => hash['returns'].to_i,
          'updates'         => hash['updates'].to_i,
          'net_downloads'   => hash['net_downloads'].to_i,
          'promos'          => hash['promos'].to_i,
          'gift_redemptions'=> hash['gift_redemptions'].to_i,
          'revenue'         => hash['revenue'].to_f
        })
      end
    end
  end

  
  def products_search(term)
    url = "products/search/#{term}"
    puts "calling: %s" % url
    self.connection.get(url).body.map do |hash|
        Hashie::Mash.new({
          'public_product_id' => hash['public_product_id'],
          'refno'             => hash['refno'],
          'sku'               => hash['sku'],
          'name'              => hash['name'],
#           'developer'         => hash['developer'],
          'icon'              => hash['icon'],
          'price'             => hash['price']['value'],
          'store'             => hash['store']
        })
    end    
  end


  def products_search(term)
    url = "products/search/#{term}"
    puts "calling: %s" % url
    self.connection.get(url).body.map do |hash|
      Hashie::Mash.new({
                           'public_product_id' => hash['public_product_id'],
                           'refno'             => hash['refno'],
                           'sku'               => hash['sku'],
                           'name'              => hash['name'],
                           #           'developer'         => hash['developer'],
                           'icon'              => hash['icon'],
                           'price'             => hash['price']['value'],
                           'store'             => hash['store']
                       })
    end
  end

  def scrape_top_ranked_apps(options)
    self.login()
    url = (options[:url] if options[:url]) || "https://appfigures.com/api/ranks/snapshots/current/US/17003/free"
    page = mechanize.get(url)
    response_json = JSON.parse(page.body)
    return (response_json['entries'] if response_json and response_json['entries']) || nil
  end
  

end


