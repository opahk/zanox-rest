module ZanoxAPI
  class Report < API

    def basic(from, to, options = {})
      options.merge!(fromdate: format_date(from), todate: format_date(to))
      request '/reports/basic', options
    end

    def sales(date, options = {})
      request '/reports/sales/date/' + format_date(date), options
    end

    def salesitem(sale_id, options = {})
      request '/reports/sales/sale/' + sale_id, options
    end

    def leads(date, options = {})
      request '/reports/leads/date/' + format_date(date), options
    end

    def leadsitem(lead_id, options = {})
      request '/reports/leads/lead/' + lead_id, options
    end

    def gpp(from, to, options = {})
      sales = (from.to_date..to.to_date).map do |date|
        sales(date, options)
      end

      salesitems = []
      sales.each do |salesday|
        if salesday[:items] > 0
          salesitems += salesday[:salesitems]
        end
      end
    end
  end
end
