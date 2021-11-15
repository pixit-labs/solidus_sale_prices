require 'spec_helper'

describe Spree::SalePrice do
  describe '.currently_active_per_price' do
    subject { described_class.currently_active_sale_per_price }

    context 'with multiple sales for a specific price' do
      let!(:price) { create(:international_price) }
      let!(:disabled) { create(:sale_price, price: price, enabled: false) }
      let!(:oldest_active)  { create(:active_sale_price, price: price) }
      let!(:newest_active)  { create(:active_sale_price, price: price) }

      it { is_expected.to contain_exactly(newest_active) }
    end

    context 'with deleted active sale prices' do
      let!(:price) { create(:international_price) }
      let!(:disabled) { create(:sale_price, price: price, enabled: false) }
      let!(:oldest_active)  { create(:active_sale_price, price: price) }
      let!(:newest_active)  { create(:active_sale_price, price: price) }
      it  "ignores deleted sale prices"  do
        newest_active.destroy
        is_expected.to contain_exactly(oldest_active)
      end
    end

    context 'with multiple prices for different variants' do
      let!(:price) { create(:international_price) }
      let!(:disabled) { create(:sale_price, price: price, enabled: false) }
      let!(:oldest_active)  { create(:active_sale_price, price: price) }
      let!(:newest_active)  { create(:active_sale_price, price: price) }

      let!(:another_variant_price) { create(:international_price) }
      let!(:another_variant_disabled) { create(:sale_price, price: another_variant_price, enabled: false) }
      let!(:another_variant_oldest_active) { create(:active_sale_price, price: another_variant_price) }
      let!(:another_variant_newest_active) { create(:active_sale_price, price: another_variant_price) }

      it { is_expected.to contain_exactly(another_variant_newest_active, newest_active) }
    end

    context 'with active sale price for both master and other variant' do
      let!(:master) { create(:variant, is_master: true) }
      let!(:variant) { create(:variant, is_master: false, product: master.product) }

      let!(:master_price) { create(:international_price, variant: master) }
      let!(:price) { create(:international_price, variant: variant) }
      let!(:master_sale) { create(:sale_price, price: master_price, enabled: true) }
      let!(:sale) { create(:sale_price, price: price, enabled: true) }

      it { is_expected.to contain_exactly(sale, master_sale) }
    end

  end
end
