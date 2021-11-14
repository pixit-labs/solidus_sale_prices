require "spec_helper"

RSpec.describe Spree::Product, type: :model do
  describe ".sort_by_master_sale_price_value_or_default_price_amount_asc" do
    let!(:product_1) { create :product, price: 20 }
    let!(:product_2) { create :product, price: 10 }
    let!(:product_3) { create :product, price: 15 }

    context "without any sales" do
      it "returns the products ordered by ascending master price" do
        result = described_class.sort_by_master_sale_price_value_or_default_price_amount_asc
        expect(result).to eq [product_2, product_3, product_1]
      end
    end

    context "with sales defined for non master variants" do
      let!(:variant) { create(:variant, product: product_1) }

      it "returns the products ordered by ascending master price" do
        variant.put_on_sale 5
        result = described_class.sort_by_master_sale_price_value_or_default_price_amount_asc
        expect(result).to eq [product_2, product_3, product_1]
      end
    end

    context "with sales defined for some master variants" do
      it "returns the products ordered by combined sale price and master pice column ascending order" do
        product_1.master.put_on_sale(5)

        result = described_class.sort_by_master_sale_price_value_or_default_price_amount_asc
        expect(result).to eq [product_1, product_2, product_3]
      end
    end

    context "with sales defined for all master variants" do
      it "returns the products ordered by ascending master sale price" do
        product_1.master.put_on_sale(5)
        product_2.master.put_on_sale(1)
        product_3.master.put_on_sale(3)
        result = described_class.sort_by_master_sale_price_value_or_default_price_amount_asc
        expect(result).to eq [product_2, product_3, product_1]
      end

      it "returns the products ordered by ascending master price if products have the same sale price" do
        product_1.master.put_on_sale(5)
        product_2.master.put_on_sale(5)
        product_3.master.put_on_sale(1)

        result = described_class.sort_by_master_sale_price_value_or_default_price_amount_asc
        expect(result).to eq [product_3, product_2, product_1]
      end
    end
  end

  describe ".sort_by_master_sale_price_value_or_default_price_amount_desc" do
    let!(:product_1) { create :product, price: 20 }
    let!(:product_2) { create :product, price: 10 }
    let!(:product_3) { create :product, price: 15 }

    context "without any sales" do
      it "returns the products ordered by descending master price" do
        result = described_class.sort_by_master_sale_price_value_or_default_price_amount_desc
        expect(result).to eq [product_1, product_3, product_2]
      end
    end

    context "with sales defined for non master variants" do
      let!(:variant) { create(:variant, product: product_1) }

      it "returns the products ordered by descending master price" do
        variant.put_on_sale 5
        result = described_class.sort_by_master_sale_price_value_or_default_price_amount_desc
        expect(result).to eq [product_1, product_3, product_2]
      end
    end

    context "with sales defined for some master variants" do
      it "returns the products ordered by combined sale price and master pice column descending order" do
        product_1.master.put_on_sale(12)

        result = described_class.sort_by_master_sale_price_value_or_default_price_amount_desc
        expect(result).to eq [product_3, product_1, product_2]
      end
    end

    context "with sales defined for all master variants" do
      it "returns the products ordered by descending master sale price" do
        product_1.master.put_on_sale(5)
        product_2.master.put_on_sale(1)
        product_3.master.put_on_sale(2)
        result = described_class.sort_by_master_sale_price_value_or_default_price_amount_desc
        expect(result).to eq [product_1, product_3, product_2]
      end

      it "returns the products ordered by descending master price if products have the same sale price" do
        product_1.master.put_on_sale(5)
        product_2.master.put_on_sale(5)

        result = described_class.sort_by_master_sale_price_value_or_default_price_amount_desc
        expect(result).to eq [product_3, product_1, product_2]
      end
    end
  end
end
