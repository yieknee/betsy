require "test_helper"

describe ProductsController do
  before do
    @merchant_test = merchants(:blacksmith)
    @category_test = categories(:food)
    @product_test = products(:pickles)

    @product_hash = {
      product: {
        name: "Crisp Pickles",
        description: "One jar of homegrown pickles.",
        img_url: "yourmom.com/image.jpeg",
        inventory: 40,
        price: 2,
        category_ids: [categories(:food).id, categories(:lifestyle).id]
      }
    }
  end

  describe "index" do
    it "can get the products path" do
      get products_path

      must_respond_with :success
    end

    it "can get the nested merchant products path of a valid merchant" do
      get merchant_products_path(@merchant_test.id)
      
      must_respond_with :success
    end

    it "will redirect to merchants index for an invalid merchant products path" do
      get merchant_products_path(-5)
      
      must_respond_with :redirect
      must_redirect_to merchants_path
    end

    it "can get the nested category products path" do
      get category_products_path(@category_test.id)
      
      must_respond_with :success
    end

    it "will redirect to categories index for an invalid category products path" do
      get category_products_path(-5)
      
      must_respond_with :redirect
      must_redirect_to categories_path
    end
  end

  describe "show" do
    it "will get show for valid ids" do
      valid_product = products(:tent)
  
      get "/products/#{valid_product.id}"
  
      must_respond_with :success
    end
  
    it "will respond with not_found for invalid ids" do
      invalid_product_id = -5
  
      get "/products/#{invalid_product_id}"
  
      must_respond_with :not_found
    end
  end
  
  describe "new" do
    it "can get the new_merchant_product_path" do
      get new_merchant_product_path(@merchant_test.id)

      must_respond_with :success
    end

    # it "will redirect to the root if merchant isn't logged in" do
    #  TODO

    # end
  end

  describe "create" do
    it "will redirect to the product show page after creating a product" do
      post merchant_products_path(@merchant_test.id), params: @product_hash
  
      must_respond_with :redirect
      must_redirect_to product_path(Product.last.id)
    end

    it "can create a product with categories with logged in user" do
      expect {
        post merchant_products_path(@merchant_test.id), params: @product_hash
      }.must_differ 'Product.count', 1

      expect(Product.last.name).must_equal @product_hash[:product][:name]
      expect(Product.last.description).must_equal @product_hash[:product][:description]
      expect(Product.last.img_url).must_equal @product_hash[:product][:img_url]
      expect(Product.last.active).must_equal true
      expect(Product.last.inventory).must_equal @product_hash[:product][:inventory]
      expect(Product.last.price).must_equal @product_hash[:product][:price]
      expect(Product.last.merchant).wont_be_nil
      expect(Product.last.merchant.username).must_equal @merchant_test.username

      expect(Product.last.categories).wont_be_nil
      expect(Product.last.categories).wont_be_empty
      expect(Product.last.categories).must_include @category_test
    end

    it "can create a product without categories with logged in user" do
      @product_hash[:product][:category_ids] = []

      expect {
        post merchant_products_path(@merchant_test.id), params: @product_hash
      }.must_differ 'Product.count', 1
  
      expect(Product.last.name).must_equal @product_hash[:product][:name]
      expect(Product.last.description).must_equal @product_hash[:product][:description]
      expect(Product.last.img_url).must_equal @product_hash[:product][:img_url]
      expect(Product.last.active).must_equal true
      expect(Product.last.inventory).must_equal @product_hash[:product][:inventory]
      expect(Product.last.price).must_equal @product_hash[:product][:price]
      expect(Product.last.merchant).wont_be_nil
      expect(Product.last.merchant.username).must_equal @merchant_test.username

      expect(Product.last.categories).wont_be_nil
      expect(Product.last.categories).must_be_empty
    end
    
    it "will respond with bad request and not add a product if given invalid params" do
      @product_hash[:product][:name] = nil

      expect {
        post merchant_products_path(@merchant_test.id), params: @product_hash
      }.must_differ "Product.count", 0

      must_respond_with :bad_request
    end
  end

  describe 'cart' do
    before do
      @product = products(:pickles)
      @quantity = 2 
    end
    it "can add a product to the seassion[:cart] hash" do
      patch product_cart_path(@product.id), params:{"quantity": @quantity}

      expect(session[:cart].class).must_equal Hash
      expect(session[:cart].count).must_equal 1
      expect(session[:cart]["#{@product.id}"]).must_equal @quantity
    end

    it "will not let you add product to the cart if product has no inventory" do
      @product.inventory = 0
      @product.save
      patch product_cart_path(@product.id), params:{"quantity": @quantity}
  
      
      must_respond_with :bad_request
      expect(session[:cart].count).must_equal 0
    end

    it "will not let you add product to the cart if quantity > inventory" do
      @product.inventory = 1
      @product.save
      patch product_cart_path(@product.id), params:{"quantity": @quantity}
  
      
      must_respond_with :bad_request
      expect(session[:cart].count).must_equal 0
    end
  end

  describe 'updatequant' do
    before do
      @product = products(:pickles)
      @quantity = 2 
      patch product_cart_path(@product.id), params:{"quantity": @quantity}
    end
    it "can update product quantity sesssion[:cart] hash" do
      patch product_update_quant_path(@product.id), params:{"quantity": 4}

      expect(session[:cart].class).must_equal Hash
      expect(session[:cart].count).must_equal 1
      expect(session[:cart]["#{@product.id}"]).must_equal 4
    end

    it "will not let you update quantity to the cart if product has no inventory" do
      @product.inventory = 0
      @product.save
      patch product_update_quant_path(@product.id), params:{"quantity": 4}
  
      must_redirect_to order_cart_path
      expect(session[:cart].count).must_equal 1
      expect(session[:cart]["#{@product.id}"]).must_equal @quantity
    end

    it "will not let you add product to the cart if quantity > inventory" do
      @product.inventory = 1
      @product.save
      patch product_update_quant_path(@product.id), params:{"quantity": 4}
  
      must_redirect_to order_cart_path
      expect(session[:cart].count).must_equal 1
      expect(session[:cart]["#{@product.id}"]).must_equal @quantity
    end
  end

  describe 'remove_from_cart' do
    before do
      @product = products(:pickles)
      @quantity = 2 
      patch product_cart_path(@product.id), params:{"quantity": @quantity}

      @product2 = products(:tent)
      @quantity2 = 1 
      patch product_cart_path(@product2.id), params:{"quantity": @quantity2}
    end
    it "can remove product from session[:cart] hash" do
      expect(session[:cart].class).must_equal Hash
      expect(session[:cart].count).must_equal 2
      expect(session[:cart]["#{@product.id}"]).must_equal @quantity
      expect(session[:cart]["#{@product2.id}"]).must_equal @quantity2

      patch product_remove_cart_path(@product.id)
      expect(session[:cart].count).must_equal 1
      expect(session[:cart]["#{@product.id}"]).must_be_nil
      expect(session[:cart]["#{@product2.id}"]).must_equal @quantity2
    end

  end

  describe "toggle_active" do
    # it "can only be called by the merchant who owns said product" do

    # end

    it "will change an active product to inactive" do
      before_state = @product_test.active

      patch toggle_active_path(@product_test.id)
      @product_test.reload

      must_respond_with :redirect
      must_redirect_to products_path(@product_test.id)
      expect(@product_test.active).must_equal !before_state
    end

    it "will change an inactive product to active" do
      inactive_test = products(:inactive_pickles)
      before_state = inactive_test.active

      patch toggle_active_path(inactive_test.id)
      inactive_test.reload

      must_respond_with :redirect
      must_redirect_to products_path(inactive_test.id)
      expect(inactive_test.active).must_equal !before_state
    end
  end
end