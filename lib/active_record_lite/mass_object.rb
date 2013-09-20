class MassObject
  def self.set_attrs(*attributes)
    @attributes = attributes
    @attributes.each { |attribute| attr_accessor(attribute.to_sym) }
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    results.map { |result| self.new(result)}
  end

  def initialize(params = {})
    params.each do |attribute, value|
      unless self.class.attributes.include?(attribute.to_sym)
        raise 'mass assignment to unregistered attribute #{attr_name}'
      end

      self.send("#{attribute}=".to_sym, value)
    end
  end
end
