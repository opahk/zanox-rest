require 'yaml'
require 'zanox'
YAML::ENGINE.yamler = 'psych'
CONFIG = YAML.load_file('spec/zanox_data.yml')


describe "Zanox API" do

  it "establishes a connection to zanox api and gets basic report for a month in the past, checks it for sanety" do
    report = Zanox::Report.basic(Date.parse(CONFIG['basic']['fromdate']), Date.parse(CONFIG['basic']['todate']))
    report.total.should == CONFIG['basic']['total']
  end

  it "establishes a connection to zanox api and gets one hopefully correct dataset" do
    report = Zanox::Report.sales(Date.parse(CONFIG['sales']['date']))
    report.items.should == CONFIG['sales']['items']
    report.sale_items.sale_item.first.id.should == CONFIG['sales']['firstid']
    report.sale_items.sale_item.first.program.value.should == CONFIG['sales']['firstprogram']
    report.sale_items.sale_item.first.amount.to_s.should == CONFIG['sales']['firstamount'].to_s
  end

  it "accepts abitrarily nested method invokations on response object" do

    response = Zanox::Response.new({:a => 1, :b => 2})
    response.a.should == 1
    response.b.should == 2
    response.method_not_there.should be_nil
    response.method_not_there.nested_not_there.should be_nil
  end

  it "processes data correctly" do

      api_response = {"page"=>0, "items"=>1, "total"=>1, "saleItems"=>{"saleItem"=>[{"@id"=>"789050fb-0d5a-4987-94fa-2d294f28fbd1", "reviewState"=>"open", "trackingDate"=>"2012-02-13T00:00:00+01:00", "modifiedDate"=>"2012-02-14T10:40:05.937+01:00", "adspace"=>{"@id"=>"1640652", "$"=>"Boost"}, "admedium"=>{"@id"=>"507303", "$"=>"0 Textlink - Weihnachten"}, "program"=>{"@id"=>"1646", "$"=>"Amazon DE"}, "clickId"=>0, "clickInId"=>0, "amount"=>15.23, "commission"=>0.76, "currency"=>"EUR", "reviewNote"=>"ASIN: B0071LPES4", "trackingCategory"=>{"@id"=>"25809", "$"=>"23_ukn_Elektronik & Foto"}}]}}

      response = Zanox::Response.new(api_response)

      si = response.sale_items.sale_item
      si.size.should == 1
      si.first.click_id.should == 0
      si.first.click_date.should be_nil
  end

end
