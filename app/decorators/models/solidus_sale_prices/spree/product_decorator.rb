module SolidusSalePrices
  module Spree
    module ProductDecorator
      def self.prepended(base)
        base.has_many :sale_prices, through: :prices

        # sort products by master sale price value or default price amount
        # Scenarios
        # 1. when there are no sales, we sort by amount column of master variant
        # 2. when some products have a master sale price but some dont, we create a new column as a result of coalesce function.
        #    in this new column, for each product, we have either the sale price or the default master price
        #    we then order this column.
        # 3. all products have sales but some of them have the same sale price. The tie is solved by compairing their default master price.

        # We want to sort products by the master variant's active sale price value or price amount, if there is no sale price.
        # We want to take into consideration default pricing options (i.e currency)
        # 1. We join with the master variants(first left outer join)
        # 2. We then join master variants with the custom "spree.prices sorted by active sale or master price"
        # 3. then we apply some conditions about
        base.scope :sort_by_master_sale_price_value_or_default_price_amount_asc, -> {
          joins(master: :prices)
            .joins(
              <<~SQL
                LEFT OUTER JOIN (#{::Spree::SalePrice.currently_active_sale_per_price.to_sql}) as spree_sale_prices ON spree_sale_prices.price_id = spree_prices.id
              SQL
            )
            .order(Arel.sql("COALESCE(spree_sale_prices.value, spree_prices.amount)").asc, ::Spree::Price.arel_table[:amount].asc)
        }

        base.scope :sort_by_master_sale_price_value_or_default_price_amount_desc, -> {
          joins(master: :prices)
            .joins(
              <<~SQL
                LEFT OUTER JOIN (#{::Spree::SalePrice.currently_active_sale_per_price.to_sql}) as spree_sale_prices ON spree_sale_prices.price_id = spree_prices.id
              SQL
            )
            .order(Arel.sql("COALESCE(spree_sale_prices.value, spree_prices.amount)").desc, ::Spree::Price.arel_table[:amount].desc)
        }
      end

      # Essentially all read values here are delegated to reading the value on the Master variant
      # All write values will write to all variants (including the Master) unless that method's all_variants parameter is
      # set to false, in which case it will only write to the Master variant.

      delegate :active_sale_in,
        :current_sale_in,
        :next_active_sale_in,
        :next_current_sale_in,
        :sale_price_in,
        :on_sale_in?,
        :original_price_in,
        :discount_percent_in,
        :on_sale?,
        :discount_percent, :discount_percent=,
        :sale_price, :sale_price=,
        :original_price, :original_price=,
        to: :master

      # TODO also accept a class reference for calculator type instead of only a string
      def put_on_sale(value, params = {}, selected_variants = [])
        all_variants = params[:all_variants] || true
        run_on_variants(all_variants, selected_variants) { |v| v.put_on_sale(value, params) }
        touch
      end

      alias_method :create_sale, :put_on_sale

      def enable_sale(all_variants = true)
        run_on_variants(all_variants) { |v| v.enable_sale }
        touch
      end

      def disable_sale(all_variants = true)
        run_on_variants(all_variants) { |v| v.disable_sale }
        touch
      end

      def start_sale(end_time = nil, all_variants = true)
        run_on_variants(all_variants) { |v| v.start_sale(end_time) }
        touch
      end

      def stop_sale(all_variants = true)
        run_on_variants(all_variants) { |v| v.stop_sale }
        touch
      end

      private

      def run_on_variants(all_variants, selected_variants = [], &block)
        if selected_variants.present?
          scope = variants_including_master
          scope = scope.where(id: selected_variants) if selected_variants.present?
          scope.each { |v| block.call v }
        else
          if all_variants && variants.present?
            variants.each { |v| block.call v }
          end
          block.call master
        end
      end

      ::Spree::Product.prepend self
    end
  end
end
