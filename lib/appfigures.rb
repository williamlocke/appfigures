require 'appfigures/version'
require 'appfigures/connection'

require 'date'

class Appfigures
  attr_reader :connection
  def initialize(options = {})
    @connection = Appfigures::Connection.new options[:username], options[:password]
  end

  def product_sales
    self.connection.get('sales/products').body.map do |id, hash|
      Hashie::Mash.new({
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
    end.first
  end
  
  def sales_per_app(start_date, end_date)
    
    sales = self.date_sales(start_date, end_date)
    sales_data = {}
    sales.each do |sale|
      if sale['product_type'] == "app"
        if sales_data[sale.product_id].nil?
          sales_data[sale.product_id] = {}        
        end
        sales_data[sale.product_id]["revenue"] = sale.revenue
        sales_data[sale.product_id]["downloads"] = sale.downloads
        sales_data[sale.product_id]["name"] = sale.name
      else
        if sales_data[sale.parent_id].nil?
          sales_data[sale.parent_id] = {}
          sales_data[sale.parent_id]["revenue"] = 0.0
        end
        sales_data[sale.parent_id]["revenue"] += sale.revenue
      end
    end
    
    sales_array = []
    sales_data.each do |product_id, data|
      sales_array.push(
        Hashie::Mash.new({
          'product_id'     =>  product_id,
          'name'     =>  data['name'],
          'revenue'     =>  data['revenue'].to_f,
          'downloads'     =>  data['downloads'].to_i,
          'revenue_per_download' => data['revenue'].to_f / data['downloads'].to_i
        })
      )
    end
    return sales_array    
  end
  
  
  def sales_per_inapp(start_date, end_date)
    
    sales = self.date_sales(start_date, end_date)
    
    sales_data = {}
    
    
    sales.each do |sale|
      if sale['product_type'] == "inapp"
        if sales_data[sale.product_id].nil?
          sales_data[sale.product_id] = {}        
        end
        sales_data[sale.product_id]["revenue"] = sale.revenue
        sales_data[sale.product_id]["downloads"] = sale.downloads
        sales_data[sale.product_id]["name"] = sale.name
        
        sales.each do |app_sale|
          if app_sale.product_id == sale.parent_id
            sales_data[sale.product_id]["downloads"] = app_sale["downloads"]
          end
        end
      end
    end
    
    sales_array = []
    sales_data.each do |product_id, data|      
      sales_array.push(
        Hashie::Mash.new({
          'product_id'     =>  product_id,
          'name'     =>  data['name'],
          'revenue'     =>  data['revenue'].to_f,
          'downloads'     =>  data['downloads'].to_i,
          'revenue_per_download' => data['revenue'].to_f / data['downloads'].to_i
        })
      )
    end
        
    return sales_array    
  end
  
  def total_sales(start_date, end_date)
    sales_data = {"revenue"=>0.0, "downloads"=>0}
    
    sales = self.sales_per_app(start_date, end_date)
    sales.each do |sale|
      sales_data["revenue"] += sale.revenue
      sales_data["downloads"] += sale.downloads
    end
        
    return Hashie::Mash.new({
        'revenue'      => sales_data["revenue"].to_f,
        'downloads'       => sales_data['downloads'].to_i
      })
  end


end
