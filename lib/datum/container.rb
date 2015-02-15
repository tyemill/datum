require "datum/helpers"

module Datum
# @api
# A Container object holds attributes for a single data test.
class Container

  # @return [String] The name of the data test method
  attr_reader :data_method_name

  # @return [TestCase] The ActiveSupport::TestCase instance of the data test
  attr_reader :test_instance

  # @param data_method_name [String] the name of test method to be called
  # @param tst_instance [TestCase] the instance containing the data_method_name
  def initialize(data_method_name, tst_instance)
    @data_method_name = data_method_name; @test_instance = tst_instance
    @loaded_data = {}; @invoked_data = {}
    ::Datum.send(:add_container, self,
      Container.key(@test_instance, @data_method_name))
  end

  # @return [int] The total number of tests / data elements / datums
  def count; @loaded_data.count + @invoked_data.count; end;

  # @return [Hash] A Hash of data elements, datum structs for the test case
  def data; @loaded_data.merge(@invoked_data); end

  alias_method :length, :count
  alias_method :size, :count
  alias_method :test_count, :count

  # @param tst_instance [TestCase] the TestCase instance for the data_test
  # @param data_method_name [String] the name of the data_test method
  # @return [String] Container compatible Hash key
  def self.key tst_instance, data_method_name
    Helpers.build_key(tst_instance, data_method_name)
  end

private

  def add_datum datum
    test_name = Helpers.build_test_name(data_method_name, test_count + 1)
    @loaded_data[Datum.key(test_instance, test_name)] = datum
    add_data_test test_name
    [count, test_name]
  end

  def invoke_datum key, tst_case
    @invoked_data[key] = datum = @loaded_data.delete(key)
    tst_case.instance_variable_set :@datum, datum
    tst_case.send datum.container.data_method_name
  end

  def add_data_test test_name
    test_instance.send(:define_method, test_name) do
      datum_key = Datum.key(nm = self.class.to_s, __method__)
      container_key = Container.key(nm,
        Helpers.data_method_from_test_name(__method__))
      ::Datum.containers[container_key].send(:invoke_datum, datum_key, self)
    end
  end

end
end
